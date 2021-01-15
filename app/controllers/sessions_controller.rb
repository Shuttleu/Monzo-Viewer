#    This file is part of Monzo-Viewer.

#    Monzo-Viewer is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.

#    Monzo-Viewer is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Monzo-Viewer.  If not, see <https://www.gnu.org/licenses/>.

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
                return
            end
        end
        redirect_to login_error_path
        return
    end

    def logout
        cookies.delete :login
    end

end