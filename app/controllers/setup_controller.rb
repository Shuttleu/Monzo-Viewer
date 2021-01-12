class SetupController < ApplicationController

    def check_cookie
        if cookies.signed[:login] == nil || User.where("cookie" => cookies.signed[:login]).count == 0
            return "cookie_error"
        end
        return cookies.signed[:login]
    end

    def authorisation_setup
        cookie = check_cookie
        if cookie == "cookie_error"
            redirect_to login_path
            return
        end
        user = User.find_by("cookie" => cookie)
        user.client_id = params["client_id"]
        user.client_secret = params["client_secret"]
        user.save
        @client_id = params["client_id"]
        @token = cookie
    end

    def dev_portal
        cookie = check_cookie
        if cookie == "cookie_error"
            redirect_to login_path
            return
        end
    end

    def create_account
        cookie = check_cookie
        if cookie != "cookie_error"
            redirect_to accounts_path
            return
        end
        @nav = "logged_out"
    end

    def oauth_details
        cookie = check_cookie
        if cookie == "cookie_error"
            redirect_to login_path
            return
        end
        @user = User.find_by("cookie" => cookie)
    end

    def create_user
        @nav = "logged_out"
        if User.where("username" => params["username"]).count == 0
            if params["password"] != params["password_confirmation"]
                @title = "Error, Passwords do not match!"
                @link = create_account_path
                @button_text = "Go Back"
            else
                cookie = SecureRandom.uuid
                User.create("cookie" => cookie, "username" => params["username"], "password_digest" => BCrypt::Password.create(params["password"]))
                cookies.signed[:login] = cookie
                @title = "Success"
                @link = dev_portal_path
                @button_text = "Continue"
                @nav = ""
            end
        else
            @title = "Error, User #{params["username"]} already exists!"
            @link = create_account_path
            @button_text = "Go Back"
        end
    end

    def complete_authorisation
        cookie = check_cookie
        if cookie == "cookie_error"
            redirect_to login_path
            return
        end
        user = User.find_by("cookie" => cookie)
        if params[:state] != cookie
            render authorisation_error
            return
        end
        begin
            refresh = JSON.parse(RestClient.post("https://api.monzo.com/oauth2/token", {grant_type: "authorization_code", client_id: user.client_id, client_secret: user.client_secret, redirect_uri: complete_authorisation_url(), code: params[:code]}).body)
        rescue => e
            render authorisation_error
            return
        end
        @already_accounts = user.accounts.count > 0
        user.access_token = refresh["access_token"]
        user.refresh_token = refresh["refresh_token"]
        user.save
    end

    def start_afresh
        cookie = check_cookie
        if cookie == "cookie_error"
            redirect_to login_path
            return
        end
        User.find_by("cookie" => cookie).accounts.destroy_all
        redirect_to force_update_accounts_path("from_start")
    end
end
