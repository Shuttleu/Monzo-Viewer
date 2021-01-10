class SessionsController < ApplicationController

    def check_cookie
        if cookies.signed[:login] == nil || User.where("cookie" => cookies.signed[:login]).count == 0
            return "cookie_error"
        end
        return cookies.signed[:login]
    end

    def login
        cookie = check_cookie
        if cookie != "cookie_error"
            redirect_to accounts_path
            return
        end
    end

    def login_submit
        user = User.where("username" => params[:username])
        if user.count > 0
            user = user.first
            if BCrypt::Password.new(user.password_digest) == params[:password]
                user.cookie = SecureRandom.uuid
                user.save
                cookies.signed[:login] = user.cookie
                redirect_to accounts_path
            end
        end
        puts "Invalid Password"
    end

    def logout
        cookies.delete :login
    end

end