class User < ApplicationRecord
    has_many :accounts, dependent: :destroy
    has_secure_password

    def account_updater(force = false, time_to_sync = 1440)
        
        puts "Updating User: #{self.id}"
        monzo = MonzoCalls.new(self)
        sync_account = true
        resync_transactions = []
        if monzo.is_authorised?
            while sync_account
                
                sync_account = false

                monzo_accounts = monzo.get_accounts

                monzo_accounts.each do |account|
                    puts "    Updating Account: #{account["id"]}"
                    if accounts.where("account_id" => account["id"]).count == 0
                        accounts.create("account_id" => account["id"], "sort_code" => "#{account["sort_code"][0..1]}-#{account["sort_code"][2..3]}-#{account["sort_code"][4..5]}", "acc_number" => account["account_number"], "balance" => "0", "name" => account["description"])
                    end

                    user_account = accounts.find_by("account_id" => account["id"])

                    acc_balance = monzo.get_account_balance(account["id"])

                    pots = monzo.get_pots(account["id"])

                    user_pots = user_account.pots

                    puts "        Updating Pots"

                    pots.each do |pot|
                        puts "            Pot: #{pot["id"]} Updated"
                        if user_pots.where("pot_id" => pot["id"]).count == 0
                            user_pots.create("pot_id" => pot["id"], "name" => pot["name"], "current" => pot["balance"], "display" => !pot["deleted"])
                        else
                            temp_pot = user_pots.find_by("pot_id" => pot["id"])
                            if temp_pot.current != pot["balance"]
                                temp_pot.current = pot["balance"]
                                temp_pot.display = !pot["deleted"]
                                temp_pot.save
                            end
                        end
                    end

                    if user_account.transactions.count > 0
                        temp_balance = user_account.transactions.last.balance
                    else
                        temp_balance = 0
                    end

                    if force
                        user_account.savings = user_account.pots.count > 0 ? user_account.pots.where("display" => true).first.id : "no_pots"
                        user_account.threshold = 0
                        user_account.threshold_offset = 0
                        user_account.save
                        temp_time = DateTime.new(2010, 1, 1, 0, 0, 0)
                    else
                        temp_time = Time.new.ago(3600*time_to_sync)
                    end

                    transactions = monzo.get_transactions(account["id"], temp_time.strftime('%FT%TZ'))
                    puts "        Updating Transactions"
                    transactions.each do |transaction|
                        if user_account.transactions.where("transaction_id" => transaction["id"]).count == 0
                            puts "            New Transaction"
                            transaction_name = transaction["merchant"] != nil ? transaction["merchant"]["name"] : transaction["description"]
                            last_transaction = user_account.transactions.last
                            pot_transfer = false
                            coin_jar = false
                            if transaction_name.slice(0, 4) == "pot_"
                                to_or_from = transaction["amount"] < 0 ? "Transfer to pot: " : "Transfer from pot: "
                                transaction_name = to_or_from + user_account.pots.find_by("pot_id" => transaction_name).name
                            end
                            if transaction["metadata"]["trigger"] == "coin_jar"
                                pot_transfer = true
                                last_transaction.amount += transaction["amount"]
                                last_transaction.balance += transaction["amount"]
                                last_transaction.coin_amount = transaction["amount"]*-1
                                last_transaction.save
                            end
                            unless transaction["metadata"]["coin_jar_transaction"].nil?
                                coin_jar = true
                            end
                            temp_balance += transaction["amount"]

                            if user_account.threshold > 0 && transaction["amount"] > user_account.threshold && last_transaction.balance > 0 && user_account.savings != "no_pots" && !resync_transactions.include?(transaction["id"])
                                monzo.transfer_to_pot(account["id"], user_account.pots.find(user_account.savings).pot_id, transaction["amount"] - last_transaction.balance, transaction["id"])
                                sync_account = true
                                resync_transactions << transaction["id"]
                                puts "                Transaction triggered pot transfer, resyncing account when done!"
                            end
                            user_account.transactions.create("day" => Time.parse(transaction["created"]), "payee" => transaction_name, "amount" => transaction["amount"], "balance" => temp_balance, "transaction_id" => transaction["id"], "pot_transfer" => pot_transfer, "coin_jar" => coin_jar)
                        end
                    end

                    if (user_account.balance != acc_balance["balance"])
                        user_account.balance = acc_balance["balance"]
                        user_account.save
                    end
                end
            end
        end
    end
end
