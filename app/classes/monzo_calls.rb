class MonzoCalls
    BaseUrl = "https://api.monzo.com/"


    def initialize(user)
        @user = user
        @access_token = @user.access_token
    end

    def refresh_token
        begin
            refresh = JSON.parse(RestClient.post("#{BaseUrl}oauth2/token", {grant_type: "refresh_token", client_id: @user.client_id, client_secret: @user.client_secret, refresh_token: @user.refresh_token}).body)
        rescue => e
            return false
        end
        @access_token = refresh["access_token"]
        @user.access_token = refresh["access_token"]
        @user.refresh_token = refresh["refresh_token"]
        return @user.save
    end

    def is_authorised?
        begin
            response = RestClient.get("#{BaseUrl}ping/whoami", {authorization: "Bearer #{@access_token}"})
        rescue => e
            return refresh_token
        end
        return true
    end

    def get_account_balance(account_id)
        if is_authorised?
            JSON.parse(RestClient.get("#{BaseUrl}balance", {params: {"account_id" => account_id}, authorization: "Bearer #{@access_token}"}).body)
        end
    end

    def get_accounts
        if is_authorised?
            active = []
            accounts = JSON.parse(RestClient.get("#{BaseUrl}accounts", {authorization: "Bearer #{@access_token}"}).body)["accounts"]
            accounts.each do |account|
                if !account["closed"]
                    active << account
                end
            end
            return active
        end
    end

    def get_pots(account_id)
        if is_authorised?
            active = []
            pots = JSON.parse(RestClient.get("#{BaseUrl}pots", {params: {"current_account_id" => account_id}, authorization: "Bearer #{@access_token}"}).body)["pots"]
            return pots
        end
    end

    def get_transactions(account_id, since)
        if is_authorised?
            settled = []
            transactions = JSON.parse(RestClient.get("#{BaseUrl}transactions", {params: {"expand[]" => "merchant", "account_id" => account_id, "since" => since}, authorization: "Bearer #{@access_token}"}).body)["transactions"]
            transactions.each do |transaction|
                if (transaction["decline_reason"] == nil)
                    settled << transaction
                end
            end
            return settled
        end
    end

    def transfer_to_pot(account_id, pot, value, transaction)
        if is_authorised?
            dedupe = transaction + ":" + pot + ":" + account_id
            new_pot = JSON.parse(RestClient.put("#{BaseUrl}pots/#{pot}/deposit", {source_account_id: account_id, amount: value, dedupe_id: dedupe}, {authorization: "Bearer #{@access_token}"}).body)
            return new_pot["id"] == pot
        end
    end
end