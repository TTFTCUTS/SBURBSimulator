part of SBURBSim;


class DisengageMurderMode extends Scene {
		List<Player> playerList = [];  //what players are already in the medium when i trigger?
	Player player = null;


	DisengageMurderMode(Session session): super(session);


	@override
	bool trigger(playerList){
		this.playerList = playerList;
		//select a random player. if they've been triggered, random chance of going murderMode if enemies (based on how triggered.)
		this.player = rand.pickFrom(this.session.availablePlayers);
		if(this.player != null){
			if(this.player.getStat("sanity") > 1 &&  this.player.murderMode){
				return true;
			}
		}
		return false;
	}
	@override
	void renderContent(Element div){
		//alert("disengaged");
		appendHtml(div,"<br>"+this.content());
	}
	dynamic content(){
		this.player.increasePower();
		removeFromArray(this.player, this.session.availablePlayers);
		String ret = "The " + this.player.htmlTitle() + " has finally calmed their ass down enough to leave Murder Mode.  ";
		ret += " This is whatever the opposite of completely terrifying is. ";
		this.player.unmakeMurderMode();
		return ret;
	}

}
