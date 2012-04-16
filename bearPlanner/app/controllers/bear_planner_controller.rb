class BearPlannerController < ApplicationController
  #The next three lines require that some method in "application_controller.rb" 
  # be run before certain methods start
  before_filter :login_required, :except => [:signup, :home, :login]
  before_filter :cal_id_matches_user, :except =>[:create_calendar, :signup, :home, :login, :logout, :show_calendars, :show_invites, :show_invite]
  before_filter :invite_id_matches_user, :only=>[:show_invite]
  
  def home
  end

  def signup
    #Attempts to create a new user
    user = Users.new do |u| 
      u.name = params[:username]
      u.password = params[:password]
    end #creates a new instance of the user model
    if request.post? #checks if the user clicked the "submit" button on the form
      if user.save #if they have submitted the form attempts to save the user
        session[:uid] = user.id #Logs in the new user automatically
        redirect_to :action => "show_calendars" #Goes to their new calendars page
      else #This will happen if one of the validations define in /app/models/user.rb fail for this instance.
        redirect_to :action => "signup", :notice=>"An error has occurred." #Ask them to sign up again
      end
    end
  end

  def login
    if request.post? #If the form was submitted
      user = Users.find(:first, :conditions=>['name=?',(params[:username])]) #Find the user based on the name submitted
      if !user.nil? && user.password==params[:password] #Check that this user exists and it's password matches the inputted password
        session[:uid] = user.id #If so log in the user
        redirect_to :action => "show_calendars" #And redirect to their calendars
      else
        redirect_to :action => "login", :notice=> "Invalid username or password. Please try again." #Otherwise ask them to try again. 
      end
    end
  end

  def logout
    session[:uid] = nil #Logs out the user
    redirect_to :action => "home" #redirect to the homepage
  end

  def show_calendars
    @calendarArray = Calendar.find_all_by_users_id(session[:uid])
  end

  def show_calendar
    tmp=Calendar.find(params[:cal_id])
    @calName = tmp.name
    @calDescription = tmp.description
    arr = [] 
    #show invited events
    InvitedEvent.find_all_by_calendars_id(params[:cal_id]).each do |inv|
      eve=Event.find_by_id(inv.events_id)
      h = {"id" => eve.id, "name" => eve.name, "starts_at" => eve.starts_at, "ends_at" => eve.ends_at}
      arr << h
    end
    Event.find_all_by_calendars_id(params[:cal_id]).each do |eve2|
      h = {"id" => eve2.id, "name" => eve2.name, "starts_at" => eve2.starts_at, "ends_at" => eve2.ends_at}
      arr << h
    end
    @eventArray = arr
  end


  def edit_event
    toReturn = Hash.new()
    Calendar.find(:all, :conditions => ["users_id = ?", session[:uid]]).each do |rec|
      toReturn[rec.name] = rec.id
    end
    @calendars = toReturn
    
    ev = Event.find(params[:event_id])
    @eventName = ev.name
    @eventId = params[:event_id]
    @eventStarts = ev.starts_at
    @eventEnds = ev.ends_at
    @eventOwner = ev.users_id
    
    
    if ev.users_id == session[:uid]
      @invitees=[]
      InvitedEvent.find(:all, :conditions => ["events_id = ?", params[:event_id]]).each do |ttt|
        na = Users.find_by_id(ttt.users_id)
        @invitees << {"name" => na.name}
      end
      @invitees << {"name" => Users.find_by_id(session[:uid]).name}
      if request.post?
        if params[:starts_at] >= params[:ends_at]
          redirect_to :action => "create_event", :notice => "An error has occurred." , :cal_id =>params[:old_cal_id], :event_id => params[:event_id]
        else
          #update the row in event table
          ev = Event.update(params[:event_id], :name=>params[:eventName], :starts_at=>params[:starts_at], :ends_at=>params[:ends_at], :calendars_id=>params[:cal_id], :users_id => session[:uid])
          
          names=params[:invitees].split(',')
          read=[]
          dupli=[]
          for name in names
            inv = Invite.new do |v|
              tmp = Users.find_by_name(name)
              if read.include?(name) or tmp.nil? or not Invite.find(:first, :conditions => ["users_id = ? and events_id = ?", tmp.id, params[:event_id]]).nil? or tmp.id == session[:uid] or InvitedEvent.find(:first, :conditions => ["users_id = ? and events_id = ?", session[:uid], params[:event_id]])
                dupli << name
              else
                read << name
                v.events_id=ev.id
                v.users_id = Users.find_by_name(name).id
                v.messag = params[:inviteMessage]
              end
            end
            ev.save
          end
          if inv.save
            if dupli.empty? #no duplicate, all good
              redirect_to :action => "show_calendar", :cal_id => params[:cal_id]
            else
              no = "The following invited usernames are invalid/duplicates and invites were not sent:"
              dupli.each {|s| no << s + " "}
              redirect_to :action => "show_calendar", :cal_id => params[:cal_id], :notice => no
            end
          end
        end
      end
    else #if you are not the user
      if params[:notice].nil?
        ownerName = Users.find_by_id(ev.users_id).name
        messa = "You can not edit this event, contact owner: " + ownerName
        redirect_to :action => "edit_event", :notice => messa, :cal_id => params[:cal_id], :event_id => params[:event_id]
      end
    end
  end

  def create_calendar
    #after submit
    #search = 
    if not Calendar.find(:first, :conditions =>["users_id = ? and name = ?", session[:uid], params[:calName]]).nil?
      redirect_to :action => "create_calendar", :notice => "An error has occured."
    else
      cal = Calendar.new do |u|
        u.name=params[:calName]
        u.description=params[:calDescription]
        u.users_id=session[:uid]
      end
      if request.post?
        if cal.save
          #:cal_id => cal.id
          #params[:cal_id]=tmpId
          redirect_to :action => "show_calendar", :cal_id => cal.id
        else
          redirect_to :action => "create_calendar", :notice => "An error has occured."
        end
      end
     end
  end

  def edit_calendar
    tmp = Calendar.find(params[:cal_id])
    @calName = tmp.name
    @calDescription = tmp.description
    result = Calendar.update(params[:cal_id], :name=>params[:calName], :description=>params[:calDescription])
    if request.post?
      if result.save
        redirect_to :action => "show_calendar", :cal_id => result.id
      else
        #params[:notice] = "An error has occured"
        redirect_to :action => "edit_calendar", :cal_id => params[:cal_id], :notice => "An error has occured."
      end
    end
  end

  def delete_calendar
    if not Event.find(:first, :conditions => ["calendars_id = ?", params[:cal_id]]).nil? or not InvitedEvent.find(:first, :conditions => ["calendars_id = ?", params[:cal_id]]).nil?
      redirect_to :action => "show_calendar", :notice => "You can not delete a calendar that contains any events.", :cal_id => params[:cal_id]
    else
      Calendar.find(params[:cal_id]).destroy
      redirect_to :action => "show_calendars"
    end
  end

  def create_event
    toReturn = Hash.new()
    Calendar.find(:all, :conditions => ["users_id = ?", session[:uid]]).each do |rec|
      toReturn[rec.name] = rec.id
    end
    @calendars = toReturn
    if request.post?
      if params[:starts_at] >= params[:ends_at]
        redirect_to :action => "create_event", :notice => "An error has occurred." , :cal_id =>params[:cal_id]
      else
        ev = Event.new do |u|
          u.name = params[:eventName]
          u.starts_at = params[:starts_at]
          u.ends_at = params[:ends_at]
          u.users_id = session[:uid]
          u.calendars_id = params[:cal_id]
        end
        if ev.save
          names=params[:invitees].split(',')
          read=[]
          dupli=[]
          myName = Users.find_by_id(session[:uid]).name
          for name in names
            inv = Invite.new do |v|
              if read.include?(name) or Users.find_by_name(name).nil? or name == myName
                dupli << name
              else
                read << name
                v.events_id=ev.id
                v.users_id = Users.find_by_name(name).id
                v.messag = params[:inviteMessage]
              end
            end
            inv.save
          end
          if dupli.empty? #no duplicate, all good
            redirect_to :action => "show_calendar", :cal_id => params[:cal_id]
          else
            no = "The following invited usernames are invalid/duplicates and invites were not sent:"
            dupli.each {|s| no << s + " "}
            redirect_to :action => "show_calendar", :cal_id => params[:cal_id], :notice => no
          end
        end
      end
    end
  end


  def delete_event
    ev = Event.find_by_id(params[:event_id])
    if ev.users_id == session[:uid]   #you are the owner
      InvitedEvent.find_all_by_events_id(params[:event_id]).each do |inv|
        inv.destroy
      end
      Invite.find_all_by_events_id(params[:uid]).each do |invit|
        invit.destroy
      end
      ev.destroy
    else
      invEv = InvitedEvent.find(:first, :conditions => ["events_id = ? and calendars_id = ?", params[:event_id], params[:cal_id]])
      invEv.destroy
    end
    redirect_to :action => "show_calendar", :cal_id => params[:cal_id]
  end

  def show_invites
    arr=[]
    Invite.find_all_by_users_id(session[:uid]).each do |inv|
      evId= Event.find_by_id(inv.events_id)
      h={"inviteId" => inv.id, "eventName" => evId.name}
      arr << h
    end
    @allInvitees = arr
  end

  def show_invite
    toReturn = Hash.new()
    Calendar.find(:all, :conditions => ["users_id = ?", session[:uid]]).each do |rec|
      toReturn[rec.name] = rec.id
    end
    @calendars = toReturn
    @inviteId = params[:invite_id]
    inv = Invite.find_by_id(params[:invite_id])
    ev = Event.find_by_id(inv.events_id)
    @inviteMessage = inv.messag
    @eventName = ev.name
    @eventStarts = ev.starts_at
    @eventEnds = ev.ends_at
    @eventUserName = Users.find_by_id(ev.users_id).name
    
    if request.post?
      if params[:cal_id].nil?
        redirect_to :action => "show_invite", :invite_id => params[:invite_id], :notice => "An error has occurred."
      else
        #delete the row in invite
        inv.destroy
        if params[:commit] == "Accept"
          invEv = InvitedEvent.new do |u|
            u.events_id = ev.id
            u.users_id = session[:uid]
            u.calendars_id = params[:cal_id]
          end
          if invEv.save
            redirect_to :action => "show_invites"
          end
        else
          redirect_to :action => "show_invites"
        end
      end
    end
  end
end
