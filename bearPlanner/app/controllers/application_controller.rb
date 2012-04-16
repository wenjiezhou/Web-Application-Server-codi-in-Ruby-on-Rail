class ApplicationController < ActionController::Base
  protect_from_forgery

  def invite_id_matches_user
    inv = Invite.find_by_id(params[:invite_id])
    if session[:uid] == inv.users_id
      return true
    else
      redirect_to :action => "show_invites", :notice => "You can not access that invite."
      return false
    end
  end

  def cal_id_matches_user
    cal = Calendar.find_by_id(params[:cal_id])
    if session[:uid] == cal.users_id
      return true
    else
      redirect_to :action => "show_calendars", :notice =>"You can not access that item." 
    end
  end

  def login_required
    if session[:uid] #if there is a logged in user
      return true
    end #Otherwise redirect to login page
    redirect_to :controller => "bear_planner", :action=> "login", :notice=>"Please log in to view this page"
    return false 
  end
end
