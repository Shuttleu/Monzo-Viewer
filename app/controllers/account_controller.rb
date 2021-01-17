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

class AccountController < ApplicationController

    def check_cookie
        return "cookie_error" if cookies.signed[:login] == nil || User.where("cookie" => cookies.signed[:login]).count == 0
        return cookies.signed[:login]
    end

    def check_access
        cookie = check_cookie
        return cookie if cookie == "cookie_error"
        current_user = User.find_by("cookie" => cookie)
        return "first_run" if current_user.access_token == nil || current_user.access_token == ""
        return current_user
    end

    def get_user
        user = check_access
        if user == "cookie_error"
            redirect_to login_path
            return "redirected"
        elsif user == "first_run"
            redirect_to dev_portal_path
            return "redirected"
        end
        return user
    end

    def viewall
        current_user = get_user
        return if current_user == "redirected"
        @accounts = current_user.accounts
        @account_balance = {}
        @accounts.each do |account|
            total_balance = 0
            pots = account.pots
            pots.each do |pot|
                total_balance += pot.current
            end
            @account_balance[account.id] = total_balance
        end
    end

    def pot
        current_user = get_user
        return if current_user == "redirected"
        @accounts = current_user.accounts

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
        current_user = get_user
        return if current_user == "redirected"
        @accounts = current_user.accounts
        @pots = {}
        @transfer_conditions = {}
        @threshold_offset = {}
        @pulse_display = {}
        @accounts.each do |account|
            @transfer_conditions[account.id] = account.conditions
            @threshold_offset[account.id] = account.threshold_offset
            @pots[account.id] = []
            @pulse_display[account.id] = account.pulse_display
            account.pots.where("display" => true).each do |pot|
                @pots[account.id] << [pot.name, pot.id]
            end
            if @pots[account.id].count == 0
                @pots[account.id] << ["No Pots in this account at time of first sync (Please add one in the Monzo app, then hit Update Accounts", "no_pots"]
            end
        end
    end

    def update
        current_user = get_user
        return if current_user == "redirected"
        
        values = JSON.parse(request.raw_post)
        current_account = current_user.accounts.find(params[:id])
        current_account.update(values)

    end

    def create_target
        current_user = get_user
        return if current_user == "redirected"
        if params["target"].to_i != 0
            targets = current_user.accounts.find(params["id"]).pots.find(params["potid"]).targets
            targets.create("target" => params["target"].to_f * 100, "for" => params["for"])
        end
        redirect_to pot_view_path(params["id"], params["potid"])
        return
    end

    def create_pot_condition
        current_user = get_user
        return if current_user == "redirected"
        conditions = current_user.accounts.find(params["id"]).conditions
        if params["amount#{params["id"]}"].to_i == 1
            conditions.create("amount" => true, "condition" => params["target#{params["id"]}"].to_f * 100)
        else 
            conditions.create("amount" => false, "condition" => params["target#{params["id"]}"])
        end
        redirect_to user_settings_path
        return
    end

    def delete_target
        current_user = get_user
        return if current_user == "redirected"
        current_user.accounts.find(params["id"]).pots.find(params["potid"]).targets.destroy(params["targetid"])
        redirect_to pot_view_path(params["id"], params["potid"])
        return
    end

    def delete_pot_condition
        current_user = get_user
        return if current_user == "redirected"
        current_user.accounts.find(params["id"]).conditions.destroy(params["conditionid"])
        redirect_to user_settings_path
        return
    end

    def transfer_to_pot
        current_user = get_user
        return if current_user == "redirected"

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

    def graph
        current_user = get_user
        return if current_user == "redirected"
            
        begin 
            account = current_user.accounts.find(params[:id])
        rescue
            render "no_account"
            return
        end
        pots = account.pots.where("display" => true)
        temp_transactions_w_pots =  account.transactions.where.not("amount" => 0)
        temp_transactions_roundups =  temp_transactions_w_pots.where("pot_transfer" => true)
        temp_transactions = temp_transactions_w_pots.where("pot_transfer" => false).reverse_order

        graph_balance = {}
        graph_balance_w_pots = {}
        graph_balance_only_pots = {}

        graph = []

        current_balance = account.balance
        current_balance_w_pots = account.balance
        current_balance_only_pots = 0
        pots.each do |pot|
            current_balance_w_pots += pot.current
            current_balance_only_pots += pot.current
        end

        graph_balance[DateTime.current.beginning_of_day.strftime('%d-%m-%Y')] = current_balance/100.0
        graph_balance_w_pots[DateTime.current.beginning_of_day.strftime('%d-%m-%Y')] = current_balance_w_pots/100.0
        graph_balance_only_pots[DateTime.current.beginning_of_day.strftime('%d-%m-%Y')] = current_balance_only_pots/100.0
        
        months = account.pulse_display * 30

        for i in 0..months do
            day = DateTime.current.beginning_of_day.ago(3600*24*i)

            transactions_for_day = temp_transactions.where(:day => day)

            transactions_for_day_roundups = temp_transactions_roundups.where(:day => day)

            transactions_for_day_roundups.each do |transaction|
                current_balance_w_pots -= transaction.amount
            end

            transactions_for_day.each do |transaction|
                current_balance -= transaction.amount
                if !transaction.payee.include?("Transfer")
                    current_balance_w_pots -= transaction.amount
                else
                    current_balance_only_pots += transaction.amount
                end
            end
            graph_balance[day.ago(3600*24).strftime('%d-%m-%Y')] = current_balance/100.0
            graph_balance_w_pots[day.ago(3600*24).strftime('%d-%m-%Y')] = current_balance_w_pots/100.0
            graph_balance_only_pots[day.ago(3600*24).strftime('%d-%m-%Y')] = current_balance_only_pots/100.0

        end

        
        graph << {"name": "Account", "data": graph_balance.reverse_each} if account.show_balance
        graph << {"name": "Pots", "data": graph_balance_only_pots.reverse_each} if account.show_pots
        graph << {"name": "Combined", "data": graph_balance_w_pots.reverse_each} if account.show_combined

        render json: graph
    end
    
    def view
        current_user = get_user
        return if current_user == "redirected"
            
        @accounts = current_user.accounts
        begin 
            @account = @accounts.find(params[:id])
        rescue
            render "no_account"
            return
        end

        @pots = @account.pots.where("display" => true)
        temp_transactions_w_pots =  @account.transactions.where.not("amount" => 0)
        temp_transactions_roundups =  temp_transactions_w_pots.where("pot_transfer" => true)
        temp_transactions = temp_transactions_w_pots.where("pot_transfer" => false).reverse_order
        offset = (params[:transactionoffset].to_i-1)*100
        limit = 100
        @transactions = temp_transactions.offset(offset).limit(limit)
        pages = (temp_transactions.count/100)+1
        @current_page = params[:transactionoffset].to_i == 0 ? 1 : params[:transactionoffset].to_i
        @previous_page = @current_page == 1 ? 1 : @current_page-1
        @next_page = @current_page == pages ? pages : @current_page+1

        @show_graph = @account.show_balance || @account.show_pots || @account.show_combined

        @view_pages = []
        @do_dots = false
        if pages > 5
            @do_dots = true
            for i in 1..2 do
                @view_pages << i
            end
            if @current_page == 2 || @current_page == 3
                @view_pages << 3
            end
            if @current_page == 3
                @view_pages << 4
            elsif @current_page.between?(4,pages-3)
                @view_pages << @previous_page
                @view_pages << @current_page
                @view_pages << @next_page
            elsif @current_page == pages-2
                @view_pages << pages-3
            end
            if @current_page == pages-2 || @current_page == pages-1
                @view_pages << pages-2
            end
            for i in pages-1..pages do
                @view_pages << i
            end
        else
            for i in 1..pages do
                @view_pages << i
            end
        end
        
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
                    @targets[pot.id.to_s][target.id.to_s] = [target.for, target.target*100/pot.targets.sum(:target).to_f]
                    @target_comp[pot.id.to_s][target.id.to_s] = target.target/100.0
                    running_total += target.target

                else
                    a = (pot.current - running_total) / target.target.to_f
                    b = target.target*100 / pot.targets.sum(:target).to_f
                    c = a * b
                    @targets[pot.id.to_s][target.id.to_s] = [target.for, c]
                    @target_comp[pot.id.to_s][target.id.to_s] = ((pot.current-running_total) < 0 ? 0 : (pot.current-running_total)/100.0)
                    running_total += target.target
                end
            end
            if running_total == 0
                @pot_title[pot.id.to_s] = "#{pot.name} - #{view_context.number_to_currency(pot.current/100.0, unit: "£")}"
            else
                @pot_title[pot.id.to_s] = "#{pot.name} - #{view_context.number_to_currency(pot.current/100.0, unit: "£")} / #{view_context.number_to_currency(running_total/100.0, unit:"£")}"
            end
        end
    end

    def update_accounts 
        current_user = get_user
        return if current_user == "redirected"
            
        current_user.account_updater(params[:force] == "from_start")
        @accounts = current_user.accounts
    end
end
