part of SBURBSim;

//TODO grab out all the strife parts from GameEntity
/*
  Though this FEELS like it should take a back burner to the general refactoring effort, the fact
  remains that GameEntities, Players and PlayerSnapshots are all treated as interchangeable
  and in Dart they are NOT.  So I need to do inheritance proper style.
 */
class Strife {
  //TODO subclass strife for pvp but everybody lives strifes
  List<
      Team> teams; //for now, assume 2 teams, but could support more in future. think terezi +dave +dirk fighting two non-allied Jacks
  num turnsPassed = 0; //keep track for interuptions and etc.
  Session session;

  Strife(this.session, this.teams);

  num timeTillRocks = 99999999; //unless it's a royalty fight, assume no rocks.

  //TODO for now keeping old code as reference material, but delete it whole sale. it is too tangled up in "this" is a GameEntity.

  //TODO get this working, then rewrite code for each sub part.
  void startTurn(div) {
    teams.sort(); //we do this every turn because mobility can change and should effect turn order.
    for (Team team in teams) {
      team.takeTurn(
          div, turnsPassed, teams); //will handling resetting player availablity
    }
    checkForSuddenEnding(
        div); //everyone is killed. or absconded in denizen case. calls processEnding on own.
    Team winner = strifeEnded();
    if (winner != null) {
      describeEnding(div, winner); //will call processEnding.
    } else {
      turnsPassed ++;
      startTurn(div);
    }
  }

  void checkForSuddenEnding(div) {
    if (turnsPassed > timeTillRocks) {
      this.rocksFallEverybodyDies(div);
      processEnding();
    } else if (denizenDoneWithYourShit(
        div)) { //highest priority. Denizen will take care of ending their fights.
      processEnding();
    } else if (turnsPassed > 30) { //holy shit are you not finished yet???
      summonAuthor(div);
      processEnding();
    }
  }

  bool denizenDoneWithYourShit(Element div) {
    List<GameEntity> members = findMembersOfDenizenFight();
    Denizen d = members[0];
    Player p = members[1];
    if (members.length != 2) return false; //it's not a denizen fight.
    //okay, now i know it IS a denizen fight.
    if (turnsPassed > 5) return true; //you should have beaten me by now.
    if (p.godDestiny) return false; //eh, you'll be okay even if I kill you.
    if (p.getStat("currentHP") < d.getStat("power"))
      return true; //i can kill you in one hit.
    if (p.getStat("currentHP") < 2 * d.getStat("power") && p.session.rand.nextDouble() > 0.5)
      return true; //i can kill you in two hits and am worried about a critical hit.

	  return false; // need to cover all the bases! -PL
  }


  //returns [Denizen, Player] if either is null, this isn't a denizen fight.
  //denizen fights have special rules when it is 1 on 1, denizen vs player.
  //if can't find one, won't add it. so anything other than size 2 is invalid.
  List<GameEntity> findMembersOfDenizenFight() {
    Denizen d;
    Player p;
    List<GameEntity> ret = new List<GameEntity>();
    for (Team team in teams) {
      Denizen tmpd = team.findDenizen();
      Player tmpp = team.findPlayer();
      if (d == null) {
        d = tmpd;
      } else {
        return ret; //i found TWO deniznes. Hax. I call hax.
      }

      if (p == null) {
        p = tmpp;
      } else {
        return ret; //i found TWO players. Hax. I call hax.
      }
    }
    if (d != null) ret.add(d);
    if (p != null) ret.add(p);
    return ret;
  }

  //a strife is over when only one team is capable of fighting anymore. livingMinusAbsconded == 0;
  Team strifeEnded() {
    Team t;
    for (Team team in teams) { //this is the Buffalo buffallo bufallo Buffalo bufallo of this sim.
      if (team.hasLivingMembersPresent()) {
        if (t != null) {
          return null; //more than one team is still in the game.
        } else {
          t = team;
        }
      }
    }
    return t; //1 or fewer teams remain
  }


  //need to list out who is dead, who absconded, and who is alive.  Who WON.
  void describeEnding(div, winner) {
    processEnding();
    winner.level();
    winner.giveGristFromTeams(teams); //will filter out 'me'
    //TODO give winner any ITEMS (such as QUEENS RING) as well. Item should inherit from GameEntity. Maybe. It does now.
    //anything i'm missing? go check current code
    String icon = "<img src = 'images/sceneIcons/defeat_icon.png'>";
    //if even one player is on the winning side, it's a victory.
    if (winner.getPlayer() != null)
      icon = "<img src = 'images/sceneIcons/victory_icon.png'>";
    String endingHTML = "<Br><br> ${icon} The fight is over. ${winner
        .name} remains alive and unabsconded. <br>";
    div.appendHtml(endingHTML,treeSanitizer: NodeTreeSanitizer.trusted);
    winner.poseAsATeam(div);
  }


  //take care of healing the living, and leveling everyone
  void processEnding() {
    for (Team team in teams) { //bufallo
      team.interact();
      team.heal();
      team.level();
    }
  }

  void rocksFallEverybodyDies(div) {
    print("Rocks fall, everybody dies in session: " +
        session.session_id.toString());
    div.append(
        "<Br><Br> In case you forgot, freaking METEORS have been falling onto the battlefield this whole time. This battle has been going on for so long that, literally, rocks fall, everybody dies.  ");
    var spacePlayer = findAspectPlayer(session.players, "Space");
    session.rocksFell = true;
    spacePlayer.landLevel =
    0; //can't deploy a frog if skaia was just destroyed. my test session helpfully reminded me of this 'cause one of the players god tier revived adn then used the sick frog to combo session. ...that...shouldn't happen.
    killEveryone("from terminal meteors to the face");
  }

  void killEveryone(String causeOfDeath) {
    for (Team team in teams) {
      team.killEveryone(causeOfDeath);
    }
  }

  void denizenIsSoNotPuttingUpWithYourShitAnyLonger(div) {
    //print("!!!!!!!!!!!!!!!!!denizen not putting up with your shit: " + this.session.session_id);
    List<GameEntity> members = findMembersOfDenizenFight();
    Denizen denizen = members[0];
    Player player = members[1];
    div.append("<Br><Br>" + denizen.name + " decides that the " +
        player.htmlTitleBasic() +
        " is being a little baby who poops hard in their diapers and are in no way ready for this fight. The Denizen recommends that they come back after they mature a little bit. The " +
        player.htmlTitleBasic() +
        "'s ass is kicked so hard they are ejected from the fight, but are not killed.");
    if (player.session.rand.nextDouble() >
        .5) { //players don't HAVE to take the advice after all. assholes.
      player.increasePower();
      div.append(
          " They actually seem to be taking " + denizen.name + "'s advice. ");
    }
  }

  void summonAuthor(div) {
    print("author is saving AB in session: " +
        this.session.session_id.toString());
    var divID = (div.id) + "authorRocks";
    String canvasHTML = "<br><canvas id='canvas" + divID + "' width='" +
        canvasWidth.toString() + "' height=" + canvasHeight.toString() +
        "'>  </canvas>";
    div.append(canvasHTML);
    //different format for canvas code
    var canvasDiv = querySelector("#canvas" + divID);
    String chat = "";
    chat += "AB: " + Zalgo.generate("HELP!!!") + "\n";
    chat += "JR: Fuck!\n";
    chat += "JR: What's going on!? \n";
    chat += "JR: What's the problem!?\n";
    chat +=
    "JR: AB come on...fuck! Your console is blank, I can't read your logs, you gotta talk to me!\n";

    chat += "AB: " +
        Zalgo.generate("INFINITE LOOP! STRIFE. IT KEEPS HAPPENING. FIX THIS.") +
        "\n";
    chat +=
    "JR: fuck fuck fuck okay okay, i got this, i can fix this, let me turn on the meteors real quick.\n";
    chat += "JR: Okay. There. No more infinite loop. Everybody is dead. \n";
    chat += "AB: Fuck. Shit. I HATE when that happens.\n";
    chat += "JR: Yeah...\n";
    chat +=
    "AB: Like, yeah, it fucking SUCKS for me, but...then the players have to die, too.\n";
    chat +=
    "JR: That's why we're working so hard to balance the system. We'll get there, eventually. Scenes like this'll never trigger. Fights'll end naturally and not just go on forever if players find exploits. \n";
    chat += "AB: Yeah...'cause SBURB is just SO easy to balance. \n'";
    drawChatABJR(canvasDiv, chat);

    killEveryone(
        "causing dear sweet precious sweet, sweet AuthorBot to go into an infinite loop");
  }

  void levelEveryone() {
    for (Team team in teams) { //buffallo
      team.level();
    }
  }

  //TODO do i still need this? maybe i'm using it for rendering.
  //might be easier for renderer to say "if you are not a Player, return"
  List<Player> removeAllNonPlayers(List<GameEntity>players) {
    List<Player> ret = [];
    for (num i = 0; i < players.length; i++) {
      var p = players[i];
      if (p is Player) ret.add(p);
    }
    return ret;
  }
}

//it is assumed that all members are on the same side and won't hurt each other.
class Team implements Comparable{  //when you want to sort teams, you sort by mobility.
  Session session;
  List<GameEntity> members;
  List<GameEntity> potentialMembers = new List<GameEntity>(); //who is allowed to join this team mid-strife. (i.e. I would be shocked if a player showed up to help a Denizen kill their buddy).
  List<GameEntity> absconded; //this only matters for one strife, so save to the team.
  String name = ""; //TODO like The Midnight Crew.  If not given, just make it a list of all members of the team.
  bool canAbscond; //sometimes you are forced to keep fighting.
  Team.withName(this.name, this.session, this.members){
    resetFraymotifsForMembers();
  }

  Team(this.session, this.members) {
    name = "The ${GameEntity.getEntitiesNames(members)}";
    resetFraymotifsForMembers(); //usable on team creation
  }



  void resetFraymotifsForMembers(){
    for(GameEntity ge in members){
      ge.resetFraymotifs();
    }
  }


  //TODO have code for taking a turn in here. have Strife be relatively empty.
  /*
    Maybe have each member decide what to do, and then have strife apply those things?
    better than fussing with div down here and up there too.

   */
  String toString() {
    return name;
  }

  //TODO figure out a better way to handle this but right now i need to be fucking done.
  void resetPlayersAvailability(){
      for(GameEntity ge in members){
        ge.usedFraymotifThisTurn = false;
      }
  }

  void takeTurn(div, num numTurnOn, List<Team> teams) {
    resetPlayersAvailability();
    if(potentialMembers.length > 0) checkForBackup(numTurnOn,div); //longer fight goes on, more likely to get backup.  IMPORTANT: BACK UP HAS TO BE GIVEN TO THIS TEAM ON CREATION
    List<Team> otherTeams = getOtherTeams(teams);
    //loop on all members each member takes turn.
    for(GameEntity member in members) { //member will take care of checking if they are absconded or dead.
      member.takeTurn(div, this, teams);
    }
  }

  void remainingPlayersHateYou(div, GameEntity coward){
    List<GameEntity> present = getLivingMinusAbsconded();
    for(GameEntity m in present){
       var r = m.getRelationshipWith(coward);
       if(r) r.value += -5; //could be a sprite, after all.
    }
  }

  //back up can be any player in the potentialMembers list. You are responsible for populating that list on team creation.
  //doomed time players will NOT be treated any differently anymore. (though a player marked as doomed might have a different narrative).
  void checkForBackup(numTurnOn,div) {
      if(potentialMembers.length == 0) return;
      potentialMembers.sort(); //fasted members get dibs.
      List<Player> timePlayers = new List<Player>();
      for(GameEntity member in members) {
        if(member is Player){
          Player p = member;
          if(p.aspect == "Time") timePlayers.add(p);
        }
        if(!member.dead && member.session.rand.nextDouble() > .75){
          session.availablePlayers.remove(member);
          summonBackup(member, div);
          return;
        }
      }

      //nobody could come, but I have me some time players i could clone.
      for(Player p in timePlayers){
        if(!p.dead && p.session.rand.nextDouble() > .9){
          Player timeClone =Player.makeDoomedSnapshot(p);
          p.addDoomedTimeClone(timeClone);
           summonBackup(timeClone, div);
        return;
        }
      }
  }

  //handle doomed time clones here, too
  void summonBackup(GameEntity backup, div) {
    String canvasHTML = "<br><canvas id='canvasBackup${backup.id}" + (div.id) +"' width='$canvasWidth' height=$canvasHeight'>  </canvas>";
    div.appendHtml(canvasHTML,treeSanitizer: NodeTreeSanitizer.trusted);
    var canvasDiv = querySelector("#canvasBackup"+ div.id);
    if(backup.doomed){
      var canvasDiv = querySelector("#canvas"+ div.id);
      drawTimeGears(canvasDiv);
      //console.log("summoning a stable time loop player to this fight. " +this.session.session_id)
      div.appendHTML("suddenly warps in from the future. They come with a dire warning of a doomed timeline. If they don't join this fight right the fuck now, shit gets real. They have sacrificed themselves to change the timeline.");
    }else{
      if(backup is Player){
        Player p = backup;
        if(p.aspect == "Time" && p.session.rand.nextDouble() > .5){
          drawTimeGears(canvasDiv);
          //console.log("summoning a stable time loop player to this fight. " +this.session.session_id)
          div.appendHTML("The " + backup.htmlTitleHP() + " has joined the Strife!!! (Don't worry about the time bullshit, they have their stable time loops on LOCK. No doom for them.)",treeSanitizer: NodeTreeSanitizer.trusted);
          return;
          }
      }//not a time player
      //console.log("summoning a player to this fight. " +this.session.session_id)
      String canvasHTML = "<br><canvas id='canvasDoomed${backup.id}" + (div.id) +"' width='$canvasWidth' height=$canvasHeight'>  </canvas>";
      div.appendHtml(canvasHTML,treeSanitizer: NodeTreeSanitizer.trusted);

      div.appendHTML("The " + backup.htmlTitleHP() + " has joined the Strife!!!",treeSanitizer: NodeTreeSanitizer.trusted);
    }
    drawSinglePlayer(canvasDiv, backup);
  }



  List<GameEntity> getLiving() {
    List<GameEntity> ret = new List<GameEntity>();
    for(GameEntity ge in members) {
      if(!ge.dead) ret.add(ge);
    }
    return ret;
  }

  void killEveryone(String reason) {
    for(GameEntity ge in getLivingMinusAbsconded()) {
      ge.makeDead(reason);
    }
  }

  List<GameEntity> getLivingMinusAbsconded(){
    var living = getLiving();
    for(num i = 0; i<this.absconded.length; i++){
      removeFromArray(this.absconded[i], living);
    }
    return living;
  }

  num getTeamStatTotal(statName) {
    num ret = 0;
    for(GameEntity ge in members) {
      ret += ge.getStat(statName);
    }
    return ret;
  }

  num getTeamStatAverage(statName) {
    num ret = 0;
    if(members.length <= 0) return ret;
    for(GameEntity ge in members) {
      ret += ge.getStat(statName);
    }
    return ret/members.length;
  }

  @override  //sorting Teams automatically sorts them by mobility so strife knows turn order
  int compareTo(other) {
    return (other.getTeamStatAverage("mobility") - getTeamStatAverage("mobility")).round();
  }

  bool hasLivingMembersPresent() {
      return this.getLivingMinusAbsconded().length > 0;
  }

  void level() {
    for(GameEntity ge in members) {
      ge.increasePower(); //don't care who you are.
    }
  }

  void heal() {
    for(GameEntity ge in members) {
      ge.heal(); //
    }
  }

  void interact() {
    for(GameEntity ge1 in members) {
      for(GameEntity ge2 in members) {
        ge2.interactionEffect(ge1); //it'll handle friendship and aspect stuff.
      }
    }
  }

  //will print out all deaths. and also cause them. because you don't auto die when hp is less than zero.
  void checkForAPulse(div, List<Team> enemyTeams) {
    String ret = "";
    for(GameEntity member in members) {
      if(!member.dead) {
          ret += member.checkDiedInAStrife(enemyTeams);
      }
    }
    if(ret.isEmpty) div.appendHTML(ret,treeSanitizer: NodeTreeSanitizer.trusted);
  }

  void giveGristFromTeams(List<Team>teams) {
    List<Team> otherTeams = getOtherTeams(teams);
    for(Team team in otherTeams) { //bufallo
      giveGrist(team.takeGrist());
    }
  }

  //return how much grist you took from teh team
  //take half of each members grist.
  num takeGrist() {
    num ret = 0;
    for(GameEntity member in members) {
      ret += member.grist/2;
      member.grist += -1 * (member.grist/2).round();
    }
    return ret.round();
  }

  void giveGrist(num gristAmount) {
      for(GameEntity member in members) {
        member.grist += (gristAmount/members.length).round();
      }
  }


  //this is how you know shit just got real.
  void renderPoseAsATeam(div) {
    List<GameEntity> poseable = [];
    for(num i = 0; i<members.length; i++){
      if(members[i].renderable()) poseable.add(members[i]);
    }

    var ch = canvasHeight;
    if(poseable.length > 6){
      ch = canvasHeight*1.5; //a little bigger than two rows, cause time clones
    }
    String canvasHTML = "<br><canvas id='canvas" + div.id+"' width='" +canvasWidth.toString() + "' height="+ch.toString() + "'>  </canvas>";
    div.appendHtml(canvasHTML,treeSanitizer: NodeTreeSanitizer.trusted);
    //different format for canvas code
    var canvasDiv = querySelector("#canvas"+ div.id);
    poseAsATeam(canvasDiv, poseable); //in handle sprites

    //TODO need to figure out when to render Denizowned again.
    //if(members[0].dead && members[0].denizen.name == this.name) denizenKill(canvasDiv, players[0]);
      throw "TODO: pose as a team.";
  }

  //Denizen fights work differently
  GameEntity findDenizen() {
      for(GameEntity ge in members) {
        if(ge is Denizen) return ge;
      }
      return null;
  }

  //need to find jack in particular so that i can have custom death graphic
  GameEntity findJack() {
    for(GameEntity ge in members) {
      if(ge.name == "Jack") return ge;
    }
    return null;
  }

  //need to find king in particular so that i can have custom death graphic
  GameEntity findKing() {
    for(GameEntity ge in members) {
      if(ge.name == "Black King") return ge;
    }
    return null;
  }

  //player fights work differently
  GameEntity findPlayer() {
    for(GameEntity ge in members) {
      if(ge is Player) return ge;
    }
    return null;
  }




  //don't include me.
  List<Team> getOtherTeams(List<Team>teams) {
    List<Team> ret = new List<Team>();
    for(Team team in teams) {
      if(team != this) ret.add(team);
    }
    return ret;
  }

  static num getTeamsStatAverage(List<Team> teams, statName) {
    num ret = 0;
    for(Team team in teams) {
     ret += (team.getTeamStatAverage(statName));
    }
    return ret;
  }

  static num getTeamsStatTotal(List<Team> teams, statName) {
    num ret = 0;
    for(Team team in teams) {
      ret += (team.getTeamStatTotal(statName));
    }
    return ret;
  }


  static String getTeamsNames(List<Team> teams) {
    return teams.join(",");  //TODO put an and at last team.
  }

  static GameEntity findJackInTeams(List<Team> teams) {
      for(Team team in teams) { //moooo
        GameEntity possibleJack = team.findJack();
        if(possibleJack != null) return possibleJack;
      }
      return null;
  }

  static GameEntity findKingInTeams(List<Team> teams) {
    for(Team team in teams) { //moooo
      GameEntity possibleKing = team.findKing();
      if(possibleKing != null) return possibleKing;
    }
    return null;
  }

}