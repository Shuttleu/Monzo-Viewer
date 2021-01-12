namespace :accounts do
    desc "Update all accounts (Balances, Transactions, Pots, etc.)"
    task :update, [:hours] => [:environment] do |task, args|

        args.with_defaults(:hours => "2")

        if args[:hours].to_i > 0
            time_to_sync = args[:hours].to_i
        else
            time_to_sync = 2
        end

        puts "Updating All Accounts with the last #{time_to_sync} hours of data as of #{Time.new.strftime('%d-%m-%Y %H:%M')}"
        User.all.each do |user|
            user.account_updater(false, 2)
        end
    end
end
