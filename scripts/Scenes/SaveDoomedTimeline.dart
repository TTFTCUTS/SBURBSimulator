part of SBURBSim;


//if leader dies before last player is in OR before performing ectobiology, it's a doomed timeline.
class SaveDoomedTimeLine extends Scene {
	List<dynamic> playerList = [];  //what players are already in the medium when i trigger?
	var timePlayer = null;
	var leaderPlayer = null;
	String reason = "";
	var doomedTimeClone = null;
	var enablingPlayer = null;	


	SaveDoomedTimeLine(Session session): super(session);

	@override
	bool trigger(playerList){
		this.timePlayer = null;
		this.enablingPlayer = null;
		var times = findAllAspectPlayers(this.session.players, "Time"); //they don't have to be in the medium, though
		this.enablingPlayer = getRandomElementFromArray(times); //ironically will probably allow more timeless sessions without crashes.
		this.leaderPlayer = getLeader(session.players);
		this.playerList = playerList;
		
		if(this.enablingPlayer){
			if(this.enablingPlayer.isActive() || Math.seededRandom() > .5){
				this.timePlayer = this.enablingPlayer;
			}else{  //somebody else can be voided.
				this.timePlayer = getRandomElementFromArray(this.session.players);  //passive time players make doomed clones of others.
			}
		}
		/*
		if(this.timePlayer.dead){  //a dead time player can't prevent shit.
			//print("time player is dead, not triggering");
			//print(this.timePlayer);
			return false;
		}*/
		//print("time player is not dead,  do i trigger?");
		return (this.timePlayer && (this.ectoDoom() || this.playerDoom() || this.randomDoom(times.length)));
	}

	@override
	void renderContent(div){
		print("time clone " + this.timePlayer + " " + this.session.session_id);
		div.append("<br><img src = 'images/sceneIcons/time_icon.png'>"+this.content());
		var divID = (div.attr("id"));
		String canvasHTML = "<br><canvas id;='canvas" + divID+"' width='" +canvasWidth + "' height;="+canvasHeight + "'>  </canvas>";
		div.append(canvasHTML);
		var canvas = querySelector("#canvas"+ divID);
		drawTimeGears(canvas, this.doomedTimeClone);
		drawSinglePlayer(canvas, this.doomedTimeClone);

	}
	bool leaderIsFucked(){
		if(this.leaderPlayer.dead && !this.leaderPlayer.dreamSelf && !this.leaderPlayer.godTier && !this.leaderPlayer.godDestiny){
			//print('leader is fucked');
			return true;
		}
		return false;
	}
	bool ectoDoom(){
		if(this.leaderIsFucked() && !this.session.ectoBiologyStarted){
			this.reason = "Leader killed before ectobiology.";
			//print(this.reason);
			return true; //paradox, the babies never get made.
		}
		return false;
	}
	bool playerDoom(){
		//greater time pressure for getting all players in, can't wait for a revive.
		if(this.leaderPlayer.dead && this.playerList.length < this.session.players.length && this.playerList.length != 1){ //if i die before entering, well, that's yellowYard bullshit
			this.reason = "Leader killed before all players in medium.";  //goddamn it past jr, there was a TYPO here, no WONDER it never happened.
			print("!!!!!!!!!!!!!!!oh hell YES " + this.session.session_id);
			return true; //not everybody is in, leader can't be server for final player
		}
		return false;
	}
	bool randomDoom(numTries){
		this.reason = "Shenanigans";
		for(int i = 0; i<numTries; i++){
			 if(Math.seededRandom() > .99) return true;
		}
		return false;
	}
	dynamic content(){
		String ret = "Minutes ago, but not many, in a slightly different timeline, a " + this.timePlayer.htmlTitleBasic() + " suddenly warps in from the future. ";
		ret += " They come with a dire warning of a doomed timeline. ";
		if(this.enablingPlayer != this.timePlayer){
			print("nonTime player doomed time clone: " + this.session.session_id);
			ret += " The " + this.enablingPlayer.htmlTitleBasic() + " helped them come back in time to change things. ";

		} 

		if(this.reason == "Leader killed before ectobiology."){
			//alert("ecto doom");
			ret += " If the " + this.leaderPlayer.htmlTitleBasic() + " dies right now, ";
			ret += " none of the Players will even be born in the first place (Long story, just trust them). ";

			this.session.doomedTimelineReasons.push(this.reason);
			this.leaderPlayer.dead = false;
			this.leaderPlayer.renderSelf();
			var r = this.timePlayer.getRelationshipWith(this.leaderPlayer);
			if(r && r.value != 0){
					if(r.value > 0){
						print(" fully restoring leader health from time shenanigans: " + this.session.session_id);
						ret += " They make it so that never happened. Forget about it. ";
						this.leaderPlayer.currentHP = this.leaderPlayer.hp;
					}else{
						print(" barely restoring leader health from time shenanigans: " + this.session.session_id);
						ret += " They take a twisted pleasure out of waiting until the last possible moment to pull the " + this.leaderPlayer.htmlTitleBasic() + "'s ass out of the danger zone. ";
						this.leaderPlayer.currentHP = this.leaderPlayer.hp/10;
					}
			}else{
				print(" half restoring leader health from time shenanigans: " + this.session.session_id);
				this.leaderPlayer.currentHP = this.leaderPlayer.hp/2;
				ret += " They interupt things before the " + this.leaderPlayer.htmlTitleBasic() +  " gets hurt too bad. ";
			}

		}else if(this.reason == "Leader killed before all players in medium."){
			ret += " If the " + this.leaderPlayer.htmlTitleBasic() + " dies right now, ";
			ret += " the " +this.session.players[this.session.players.length-1].htmlTitleBasic() + " will never even make it into the medium. "; //only point of paradox is for last player
			ret += " After all, the " + this.leaderPlayer.htmlTitleBasic() + " is their server player. ";
			this.leaderPlayer.dead = false;
			this.leaderPlayer.renderSelf();
			var r = this.timePlayer.getRelationshipWith(this.leaderPlayer);
			if(r && r.value != 0){
					if(r.value > 0){
						print(" fully restoring leader health from time shenanigans before all players in session: " + this.session.session_id);
						ret += " They make it so that never happened. Forget about it. ";
						this.leaderPlayer.currentHP = this.leaderPlayer.hp;
					}else{
						print(" barely restoring leader health from time shenanigans before all players in session : " + this.session.session_id);
						ret += " They take a twisted pleasure out of waiting until the last possible moment to pull the " + this.leaderPlayer.htmlTitleBasic() + "'s ass out of the danger zone. ";
						this.leaderPlayer.currentHP = this.leaderPlayer.hp/10;
					}
			}else{
				print(" half restoring leader health from time shenanigans before all players in session: " + this.session.session_id);
				ret += " They interupt things before the " + this.leaderPlayer.htmlTitleBasic() +  " gets hurt too bad. ";
				this.leaderPlayer.currentHP = this.leaderPlayer.hp/2;
			}
			this.session.doomedTimelineReasons.push(this.reason);
		}else{
			if(this.timePlayer.leader && !this.session.ectoBiologyStarted ){
					print("time player doing time ectobiology: " + this.session.session_id);
					this.timePlayer.performEctobiology(this.session);
					this.reason = "Time player didn't do ectobiology.";
					session.doomedTimelineReasons.push(this.reason);
					ret += " They need to do the ectobiology right freaking now, or none of the players will ever even be born.";
			}else{
				this.reason = "Shenanigans";
				session.doomedTimelineReasons.push(this.reason);
				ret += " It's too complicated to explain, but everyone has already screwed up beyond repair. Just trust them. ";
			}
		}



		var living = findLivingPlayers(this.session.players);
		if(living.length > 0){
			ret += " The " + this.timePlayer.htmlTitleBasic() + " has sacrificed themselves to change the timeline. ";
			ret += " YOUR session's " + this.timePlayer.htmlTitle() + " is fine, don't worry about it...but THIS one is now doomed. ";
			ret += " Least they can do after saving everyone is to time travel to where they can do the most good. ";
			ret += " After doing something inscrutable, they vanish in a cloud of clocks and gears. ";
		}else{
			print("death's hand maid in: " + this.session.session_id);
			ret += " Time really is the shittiest aspect. They make sure everybody is dead in this timeline, as per inevitability's requirements, then they sullenly vanish in a cloud of clocks and gears. ";
		}
		this.doomedTimeClone = makeDoomedSnapshot(this.timePlayer);
		this.timePlayer.doomedTimeClones.push(this.doomedTimeClone);
		this.timePlayer.sanity += -10;
		this.timePlayer.flipOut("their own doomed time clones");
		return ret;
	}

}