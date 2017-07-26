part of SBURBSim;


class BeTriggered extends Scene{
	bool canRepeat = true;
	List<dynamic> playerList = [];  //what players are already in the medium when i trigger?
	List<dynamic> triggeredPlayers = [];
	List<dynamic> triggers = [];


	BeTriggered(Session session): super(session);

	@override
	dynamic trigger(playerList){
		this.playerList = playerList;
		this.triggeredPlayers = [];
		for(num i = 0; i<this.session.availablePlayers.length; i++){
			var p = this.session.availablePlayers[i];
			if(this.IsPlayerTriggered(p) && rand.nextDouble() >.75){ //don't all flip out/find out at once. if i find something ELSE to flip out before i can flip out about this, well, oh well. SBURB is a bitch. 75 is what it should be when i'm done testing.
				//print("shit flipping: " + p.flipOutReason + " in session " + this.session.session_id);
				this.triggeredPlayers.add(p);
			}
		}
		return this.triggeredPlayers.length > 0;
	}
	@override
	void renderContent(div){
		div.append("<br><img src = 'images/sceneIcons/flipout_icon_animated.gif'>"+this.content());
	}
	bool IsPlayerTriggered(player){
		if(player.flipOutReason){
			//print("I have a flip out reason: " + player.flipOutReason);
			if(player.flippingOutOverDeadPlayer && player.flippingOutOverDeadPlayer.dead){
				//print("I know about a dead player. so i'm gonna start flipping my shit. " + this.session.session_id);
				return true;
			}else if(player.flippingOutOverDeadPlayer){ //they got better.
			//	print(" i think i need to know about a dead player to flip my shit. " + player.flippingOutOverDeadPlayer.title())
				player.flipOutReason = null;;
				player.flippingOutOverDeadPlayer = null;
				return false;
			}
			if(player.flipOutReason == "being haunted by their own ghost") print("flipping otu over own ghost" + this.session.session_id.toString());
			//"being haunted by the ghost of the Player they killed"
				if(player.flipOutReason == "being haunted by the ghost of the Player they killed") print("flipping otu over victim ghost" + this.session.session_id.toString());
			///okay. player.flippingOutOverDeadPlayer apparently can be null even if i totally and completely am flipping otu over a dead player. why.
			//print("preparing to flip my shit. and its about " + player.flipOutReason + " which BETTEr fucking not be about a dead player. " + player.flippingOutOverDeadPlayer);
			return true; //i am flipping out over not a dead player, thank you very much.

		}
		if(-1 * player.getStat("sanity") > rand.nextDouble() * 100 ){
			player.flipOutReason = "how they seem to be going shithive maggots for no goddamned reason";
			return true;
		}
		return false;
	}
	String IsPlayerTriggeredOld(player){
		//are any of your friends  dead?
		var deadPlayers = findDeadPlayers(this.session.players);
		var deadFriends = player.getFriendsFromList(deadPlayers);
		var livePlayers = findLivingPlayers(this.session.players);
		var worstEnemy = player.getWorstEnemyFromList(this.session.players);
		var bestFriend = player.getBestFriendFromList(this.session.players);

		var deadDiamond = player.hasDeadDiamond();
		var deadHeart = player.hasDeadHeart();
		if(deadDiamond && rand.nextDouble() > 0.3){
			player.sanity += -1000;
			player.damageAllRelationships();
			player.damageAllRelationships();
			player.damageAllRelationships();
			//print("triggered by dead moirail in session" + this.session.session_id);
			return " their dead Moirail, the " + deadDiamond.htmlTitleBasic() + " ";
		}

		if(deadHeart&& rand.nextDouble() > 0.2){
			player.sanity += -1000;
			//print("triggered by dead matesprit in session" + this.session.session_id);
			return " their dead Matesprit, the " + deadHeart.htmlTitleBasic() + " ";
		}
		//small chance
		if(deadPlayers.length > 0){
			if(rand.nextDouble() > 0.9){
				player.sanity += -10;
				return deadPlayers.length +" dead players ";
			}

			if(worstEnemy != null && !worstEnemy.dead && player.getRelationshipWith(worstEnemy).type() == player.getRelationshipWith(worstEnemy).badBig){
				player.sanity += -30;
				player.getRelationshipWith(worstEnemy).decrease();
				return deadPlayers.length + " players are dead (and that asshole the " + worstEnemy.htmlTitle() + " MUST be to blame) ";
			}
		}

		//bigger chance
		if(deadFriends.length > 0){
			if(rand.nextDouble() > 0.5){
				player.sanity += -10;
				return deadFriends.length + " dead friends";
			}

			//if someone you have a crush on dies, you're triggered. period. (not necessarily gonna lose your shit, though.)
			if(bestFriend != null && bestFriend.dead && player.getRelationshipWith(bestFriend).type() == player.getRelationshipWith(bestFriend).bigGood){
				player.sanity += -30;
				return " their dead crush, the " + bestFriend.htmlTitle() + " ";
			}

		}

		//huge chance, the dead outnumber the living.
		if(deadPlayers.length > livePlayers.length){
			if(rand.nextDouble() > 0.1){
				player.sanity += -30;
				return " how absolutely fucked they are ";
			}
		}

		if(player.doomedTimeClones.length > 0 && rand.nextDouble() > .9){
			player.sanity += -10;
			return " their own doomed Time Clones ";
		}

		if(player.denizenFaced && player.denizenDefeated && rand.nextDouble() > .95){
			player.sanity += -10;
			return " how terrifying " +player.getDenizen() + " was " ;
		}

		//TODO have triggers specific to classes or aspects, like time players having to abort a timeline.
		return " absolutely nothing ";

	}
	dynamic content(){
		String ret = "";
		for(num i = 0; i<this.triggeredPlayers.length; i++){
			Player p = this.triggeredPlayers[i];
			Player hope = findAspectPlayer(findLivingPlayers(this.session.players), "Hope");
			if(hope!=null && hope.getStat("power") > 100){

				//print("Hope Survives: " + this.session.session_id);
				ret += " The " +p.htmlTitle() + " should probably be flipping the fuck out about  " + p.flipOutReason;
				ret += " and being completely useless, but somehow the thought that the " + hope.htmlTitle() + " is still alive fills them with determination, instead.";  //hope survives.
				hope.increasePower();
				p.increasePower();
				p.flipOutReason = null;
				p.flippingOutOverDeadPlayer = null;

			}else{
				removeFromArray(p, this.session.availablePlayers);
				ret += " The " +p.htmlTitle() + " is currently too busy flipping the fuck out about ";
				ret += p.flipOutReason + " to be anything but a useless piece of gargbage. ";
				p.addStat("sanity", -10);
				p.flipOutReason = null;
				p.flippingOutOverDeadPlayer = null;
				if(p.getStat("sanity") < -5){
					ret += " Their freakout level is getting dangerously high. ";
				}
			}
		}
		return ret;
	}

}
