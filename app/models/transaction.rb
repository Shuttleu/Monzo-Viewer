class Transaction < ApplicationRecord
    belongs_to :account

    def next
        user.accounts.transactions.where("created_at > ? AND ", id).first
    end

    def prev
        Account.find(account_id).transactions.where("created_at < ?", created_at).last
    end
end
