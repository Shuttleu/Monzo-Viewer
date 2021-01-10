class User < ApplicationRecord
    has_many :accounts, dependent: :destroy
    has_secure_password
end
