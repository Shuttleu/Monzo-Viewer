class AccountController < ApplicationController

    def check_cookie
        if cookies.signed[:login] == nil || User.where("cookie" => cookies.signed[:login]).count == 0
            return "cookie_error"
        end
        return cookies.signed[:login]
    end

    def check_access
        cookie = check_cookie
        if cookie == "cookie_error"
            return cookie
        end
        current_user = User.find_by("cookie" => cookie)
        if current_user.access_token == nil || current_user.access_token == ""
            return "first_run"
        end
        return cookie
    end

    def viewall
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        @current_user = User.find_by("cookie" => cookie)
        @accounts = @current_user.accounts
    end

    def secret
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        @current_user = User.find_by("cookie" => cookie)
        @accounts = @current_user.accounts
    end

    def update_secret
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        current_user = User.find_by("cookie" => cookie)
        current_user.client_id = params[:client_id]
        current_user.access_token = params[:access_token]
        current_user.refresh_token = params[:refresh_token]
        current_user.client_secret = params[:secret]
        current_user.save
    end

    def pot
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        @current_user = User.find_by("cookie" => cookie)
        @accounts = @current_user.accounts

        begin 
            account = @accounts.find(params[:id])
        rescue
            render "no_account"
            return
        end

        begin 
            @pot = account.pots.find(params[:potid])
        rescue
            render "no_pot"
            return
        end
        

        @colours = ["primary", "success", "danger", "warning", "info", "secondary"]

        @targets = {}
        @target_comp = {}
        running_total = 0
        @pot.targets.each do |target|
            if target.target+running_total <= @pot.current
                @targets[target.id.to_s] = target.target*100/@pot.targets.sum(:target).to_f
                @target_comp[target.id.to_s] = target.target/100.0
                running_total += target.target

            else
                a = (@pot.current - running_total) / target.target.to_f
                b = target.target*100 / @pot.targets.sum(:target).to_f
                c = a * b
                @targets[target.id.to_s] = c
                @target_comp[target.id.to_s] = ((@pot.current-running_total) < 0 ? 0 : (@pot.current-running_total)/100.0)
                running_total += target.target
            end
        end
        if running_total == 0
            @pot_title = "#{@pot.name} - #{view_context.number_to_currency(@pot.current/100.0, unit: "£")}"
        else
            @pot_title = "#{@pot.name} - #{view_context.number_to_currency(@pot.current/100.0, unit: "£")} / #{view_context.number_to_currency(running_total/100.0, unit:"£")}"
        end
    end

    def settings
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        @current_user = User.find_by("cookie" => cookie)
        @accounts = @current_user.accounts
        @pots = {}
        @transfer_threshold = {}
        @threshold_offset = {}
        @accounts.each do |account|
            @transfer_threshold[account.id] = account.threshold
            @threshold_offset[account.id] = account.threshold_offset
            @pots[account.id] = []
            account.pots.where("display" => true).each do |pot|
                @pots[account.id] << [pot.name, pot.id]
            end
            if @pots[account.id].count == 0
                @pots[account.id] << ["No Pots in this account at time of first sync (Please add one in the Monzo app, then hit Update Accounts", "no_pots"]
            end
        end
    end

    def update_name
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        account = User.find_by("cookie" => cookie).accounts.find(params[:id])
        account.name = JSON.parse(request.raw_post)["new_name"]
        account.save
    end

    def update_savings_pot
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        values = JSON.parse(request.raw_post)
        current_account = User.find_by("cookie" => cookie).accounts.find(params[:id])
        current_account.savings = values["new_pot"]
        current_account.threshold = ((values["threshold"].to_f)*100).to_i
        current_account.threshold_offset = ((values["threshold_leave"].to_f)*100).to_i
        current_account.save
    end

    def create_target
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        if params["target"].to_i != 0
            targets = User.find_by("cookie" => cookie).accounts.find(params["id"]).pots.find(params["potid"]).targets
            targets.create("target" => params["target"].to_f * 100, "for" => params["for"])
        end
        redirect_to pot_view_path(params["id"], params["potid"])
        return
    end

    def delete_target
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        User.find_by("cookie" => cookie).accounts.find(params["id"]).pots.find(params["potid"]).targets.destroy(params["targetid"])
        redirect_to pot_view_path(params["id"], params["potid"])
        return
    end

    def transfer_to_pot
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end

        current_user = User.find_by("cookie" => cookie)
        account = current_user.accounts.find(params["id"])
        account_id = account.account_id
        pot_id = account.pots.find(account.savings).pot_id
        dedupe = params["transaction"] + ":" + pot_id + ":" + account_id
        monzo = MonzoCalls.new(current_user)
        if monzo.is_authorised?
            monzo.transfer_to_pot(account_id, pot_id, params["amount"], params["transaction"])
            update_accounts
            redirect_to account_path(params["id"])
        end
    end
    
    def view
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end

        @current_user = User.find_by("cookie" => cookie)
        @accounts = @current_user.accounts
        begin 
            @account = @current_user.accounts.find(params[:id])
        rescue
            render "no_account"
            return
        end

        @pots = @account.pots.where("display" => true)
        temp_transactions = @account.transactions.where("pot_transfer" => false).where.not("amount" => 0).reverse_order
        offset = params[:transactionoffset].to_i > 1 ? ((params[:transactionoffset].to_i-1)*100) : (params[:transactionoffset].to_i-1)*100
        limit = params[:transactionoffset].to_i > 1 ? 100 : 100
        @transactions = temp_transactions.offset(offset).limit(limit)
        @pages = (temp_transactions.count/100)+1
        @current_page = params[:transactionoffset].to_i == 0 ? 1 : params[:transactionoffset].to_i
        @previous_page = @current_page == 1 ? 1 : @current_page-1
        @next_page = @current_page == @pages ? @pages : @current_page+1

        
        @colours = ["primary", "success", "danger", "warning", "info", "secondary"]

        @targets = {}
        @target_comp = {}
        @pot_title = {}

        @pots.each do |pot|
            @targets[pot.id.to_s] = {}
            @target_comp[pot.id.to_s] = {}
            running_total = 0
            pot.targets.each do |target|
                if target.target+running_total <= pot.current
                    @targets[pot.id.to_s][target.id.to_s] = target.target*100/pot.targets.sum(:target).to_f
                    @target_comp[pot.id.to_s][target.id.to_s] = target.target/100.0
                    running_total += target.target

                else
                    a = (pot.current - running_total) / target.target.to_f
                    b = target.target*100 / pot.targets.sum(:target).to_f
                    c = a * b
                    @targets[pot.id.to_s][target.id.to_s] = c
                    @target_comp[pot.id.to_s][target.id.to_s] = ((pot.current-running_total) < 0 ? 0 : (pot.current-running_total)/100.0)
                    running_total += target.target
                end
            end
            puts running_total
            if running_total == 0
                @pot_title[pot.id.to_s] = "#{pot.name} - #{view_context.number_to_currency(pot.current/100.0, unit: "£")}"
            else
                @pot_title[pot.id.to_s] = "#{pot.name} - #{view_context.number_to_currency(pot.current/100.0, unit: "£")} / #{view_context.number_to_currency(running_total/100.0, unit:"£")}"
            end
        end
        puts @targets
        puts @target_comp

    end

    def update_accounts
        cookie = check_access
        if cookie == "cookie_error"
            redirect_to login_path
            return
        elsif cookie == "first_run"
            redirect_to dev_portal_path
            return
        end
        @current_user = User.find_by("cookie" => cookie)
        @accounts = @current_user.accounts
        monzo = MonzoCalls.new(@current_user)
        if monzo.is_authorised?
            accounts = monzo.get_accounts
            
            user_accounts = @current_user.accounts

            accounts.each do |account|
                if user_accounts.where("account_id" => account["id"]).count == 0
                    user_accounts.create("account_id" => account["id"], "sort_code" => "#{account["sort_code"][0..1]}-#{account["sort_code"][2..3]}-#{account["sort_code"][4..5]}", "acc_number" => account["account_number"], "balance" => "0", "name" => account["description"])
                end

                pots = monzo.get_pots(account["id"])

                user_account = user_accounts.find_by("account_id" => account["id"])

                user_pots = user_account.pots

                pots.each do |pot|
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

                temp_balance = user_account.transactions.last.balance
                if params[:force] == "from_start"
                    user_account.savings = user_account.pots.count > 0 ? user_account.pots.where("display" => true).first.id : "no_pots"
                    user_account.threshold = 0
                    user_account.threshold_offset = 0
                    user_account.save
                    transactions = monzo.get_transactions(account["id"], Time.new(2010, 1, 1, 0, 0, 0).strftime('%FT%TZ'))
                else
                    transactions = monzo.get_transactions(account["id"], Time.new.prev_month.at_beginning_of_day.strftime('%FT%TZ'))
                end
                transactions.each do |transaction|
                    if user_accounts.find_by("account_id" => account["id"]).transactions.where("transaction_id" => transaction["id"]).count == 0
                        transaction_name = transaction["merchant"] != nil ? transaction["merchant"]["name"] : transaction["description"]
                        pot_transfer = false
                        coin_jar = false
                        if transaction_name.slice(0, 4) == "pot_"
                            to_or_from = transaction["amount"] < 0 ? "Transfer to pot: " : "Transfer from pot: "
                            transaction_name = to_or_from + user_accounts.find_by("account_id" => account["id"]).pots.find_by("pot_id" => transaction_name).name
                        end
                        if transaction["metadata"]["trigger"] == "coin_jar"
                            pot_transfer = true
                            last_transaction = user_accounts.find_by("account_id" => account["id"]).transactions.last
                            last_transaction.amount += transaction["amount"]
                            last_transaction.balance += transaction["amount"]
                            last_transaction.coin_amount = transaction["amount"]*-1
                            last_transaction.save
                        end
                        unless transaction["metadata"]["coin_jar_transaction"].nil?
                            coin_jar = true
                        end
                        temp_balance += transaction["amount"]
                        user_accounts.find_by("account_id" => account["id"]).transactions.create("day" => Time.parse(transaction["created"]), "payee" => transaction_name, "amount" => transaction["amount"], "balance" => temp_balance, "transaction_id" => transaction["id"], "pot_transfer" => pot_transfer, "coin_jar" => coin_jar)
                    end
                end
                acc_balance = monzo.get_account_balance(account["id"])

                if (user_account.balance != acc_balance["balance"])
                    user_account.balance = acc_balance["balance"]
                    user_account.save
                end
            end
        end
    end
end
