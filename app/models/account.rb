class Account < ApplicationRecord
    belongs_to :user
    has_many :transactions, dependent: :destroy
    has_many :pots, dependent: :destroy
end
