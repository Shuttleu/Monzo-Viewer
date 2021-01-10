class Pot < ApplicationRecord
    belongs_to :account
    has_many :targets, dependent: :destroy
end
