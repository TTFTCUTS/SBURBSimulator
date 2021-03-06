part of SBURBSim;


class FaceDenizen extends Scene{

	List<dynamic> denizenFighters = [];	


	FaceDenizen(Session session): super(session);

	@override
	bool trigger(playerList){
		this.denizenFighters = [];
		this.playerList = playerList;
		for(num i = 0; i<this.session.availablePlayers.length; i++){
			var p = this.session.availablePlayers[i];
			if(p.denizen_index >= 3 && !p.denizenDefeated && p.land != null){
				var d = p.denizen;
				if(p.getStat("power") > d.getStat("currentHP") || rand.nextDouble() > .5){  //you're allowed to do other things between failed boss fights, you know.
					this.denizenFighters.add(p);
				}
			}else if(p.landLevel >= 6 && !p.denizenMinionDefeated && p.land != null){
				var d = p.denizenMinion;
				if(p.getStat("power") > d.getStat("currentHP") || rand.nextDouble() > .5){//you're allowed to do other things between failed boss fights, you know.
					this.denizenFighters.add(p);
				}
			}
		}
		return this.denizenFighters.length > 0;
	}
	dynamic addImportantEvent(player){  //TODO reimplment this for boss fights
		/*
		var current_mvp = findStrongestPlayer(this.session.players);
		//need to grab this cause if they are dream self corpse smooch won't trigger an important event
		if(player.godDestiny == false && player.isDreamSelf == true){//could god tier, but fate wn't let them
			var ret = this.session.addImportantEvent(new PlayerDiedButCouldGodTier(this.session, current_mvp.getStat("power"),player) );
			if(ret){
				return ret;
			}
			this.session.addImportantEvent(new PlayerDiedForever(this.session, current_mvp.getStat("power"),player) );
		}else if(this.session.reckoningStarted == true && player.isDreamSelf == true) { //if the reckoning started, they couldn't god tier.
			var ret = this.session.addImportantEvent(new PlayerDiedForever(this.session, current_mvp.getStat("power"),player) );
			if(ret){
				return ret;
			}
			this.session.addImportantEvent(new PlayerDiedButCouldGodTier(this.session, current_mvp.getStat("power"),player) );
		}else if(player.isDreamSelf == true){
				return this.session.addImportantEvent(new PlayerDiedForever(this.session, current_mvp.getStat("power"),player) );
		}
		*/
	}
	@override
	void renderContent(Element div){
		appendHtml(div,"<br><br>");
		for(num i = 0; i<this.denizenFighters.length; i++){
			var p = this.denizenFighters[i];
			removeFromArray(p, this.session.availablePlayers);
			if(!p.denizenMinionDefeated){
				this.faceDenizenMinion(p,div);
			}else if(!p.denizenDefeated){
				this.faceDenizen(p,div);
			}

		}
	}
	void faceDenizenMinion(Player p, Element div){
		GameEntity denizenMinion = p.denizenMinion;
		String ret = "<br>The " + p.htmlTitleHP() + " initiates a strife with the " + denizenMinion.name + ". ";
		if(p.sprite != null && p.sprite.getStat("currentHP") > 0 ) ret += " " + p.sprite.htmlTitleHP() + " joins them! ";
    appendHtml(div,ret);
		Team pTeam = new Team(this.session, [p]);
		Team dTeam = new Team(this.session, [denizenMinion]);
    dTeam.canAbscond = false;
		Strife strife = new Strife(this.session, [pTeam, dTeam]);
		strife.startTurn(div);
		if(denizenMinion.getStat("currentHP") <= 0 || denizenMinion.dead){
			p.denizenMinionDefeated = true;
		}
	}
	void faceDenizen(p, Element div){
		String ret = " ";
		var denizen = p.denizen;
		if(!p.denizenFaced && p.getFriends().length > p.getEnemies().length){ //one shot at The Choice
			//print("confront icon: " + this.session.session_id);
			ret += "<br><img src = 'images/sceneIcons/confront_icon.png'> The " + p.htmlTitle() + " cautiously approaches their " + denizen.name + " and are presented with The Choice. ";
			if(p.getStat("power") > 27){ //calibrate this l8r
				ret += " The " + p.htmlTitle() + " manages to choose correctly, despite the seeming impossibility of the matter. ";
				ret += " They gain the power they need to acomplish their objectives. ";
				p.denizenDefeated = true;
				p.addStat("power",p.getStat("power")*2);  //current and future doubling of power.
				p.leveledTheHellUp = true;
				p.grist += denizen.grist;
				appendHtml(div,"<br>"+ret);
				this.session.denizenBeat = true;
				p.fraymotifs.addAll(p.denizen.fraymotifs);
				//print("denizen beat through choice in session: " + this.session.session_id);
			}else{
				p.denizenDefeated = false;
				ret += " They are unable to bring themselves to make the clearly correct, yet impossible, Choice, and are forced to admit defeat. " + denizen.name + " warns them to prepare for a strife the next time they come back. ";
        appendHtml(div,"<br>"+ret);
			}
		}else{
			ret += "<br>The " + p.htmlTitle() + " initiates a strife with their " + denizen.name + ". ";
      appendHtml(div,ret);
      Team pTeam = new Team(this.session, [p]);
      Team dTeam = new Team(this.session, [denizen]);
      dTeam.canAbscond = false;
      Strife strife = new Strife(this.session, [pTeam, dTeam]);
      strife.startTurn(div);
			if(denizen.getStat("currentHP") <= 0 || denizen.dead) {
				p.denizenDefeated = true;
				p.fraymotifs.addAll(p.denizen.fraymotifs);
				p.addStat("power",p.getStat("power")*2);  //current and future doubling of power.
				this.session.denizenBeat = true;
			}else if(p.dead){
				//print("denizen kill " + this.session.session_id);
			}
		}
			p.denizenFaced = true; //may not have defeated them, but no longer have the option of The Choice
	}

	dynamic content(){
		String ret = "";
		for(num i = 0; i<this.denizenFighters.length; i++){
			var p = this.denizenFighters[i];
			removeFromArray(p, this.session.availablePlayers);
			//ret += "Debug Power: " + p.getStat("power");
			//fight denizen
			if(p.getFriends().length < p.getEnemies().length){
				ret += " The " + p.htmlTitle() + " sneak attacks their denizen, " + p.getDenizen() + ". ";
				if(p.getStat("power") > 7){
					ret += " They win handly, and obtain untold levels of power and sweet sweet hoarde grist. They gain all the levels. All of them. ";
					p.denizenFaced = true;
					p.addStat("power",p.getStat("power")*2);  //current and future doubling of power.
					p.level_index +=3;
					p.leveledTheHellUp = true;
					p.denizenDefeated = true;
					this.session.denizenBeat = true;
				//	print("denizen beat through violence in session: " + this.session.session_id);
				}else{
					p.denizenFaced = true;
					p.denizenDefeated = false;
					ret += " Huh.  They were NOT ready for that.  They are easily crushed by their Denizen. DEAD.";
					p.dead = true;
					p.makeDead("fighting their Denizen way too early");
				}
			}else{//do The Choice
				ret += " The " + p.htmlTitle() + " cautiously approaches their denizen, " + p.getDenizen() + " and are presented with The Choice. ";
				if(p.getStat("power") > 10){
					ret += " The " + p.htmlTitle() + " manages to choose correctly, despite the seeming impossibility of the matter. ";
					ret += " They gain the power they need to acomplish their objectives. ";
					p.denizenFaced = true;
					p.denizenDefeated = true;
					p.addStat("power",p.getStat("power")*2);   //current and future doubling of power.
					p.leveledTheHellUp = true;
					//this.session.denizenBeat = true;
					//print("denizen beat through choice in session: " + this.session.session_id);
				}else{
					p.denizenFaced = true;
					p.denizenDefeated = false;
					ret += " They are unable to bring themselves to make the clearly correct, yet impossible, Choice, and are forced to admit defeat. " + p.getDenizen() + " warns them not to come back. ";
				}
			}

		}
		return ret;
	}

}
