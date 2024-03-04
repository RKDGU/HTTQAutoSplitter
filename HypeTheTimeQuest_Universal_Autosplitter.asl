//Autosplitter for Hype - The Time Quest any% English version V1
//RayKinDar 2023 httqsplitter@yamihub.net and some code snippets used from Healer_hg 2020 https://github.com/hugarada
//Join the HTTQ Discord https://discord.gg/PGqVJTP
//For additional docs see: https://github.com/LiveSplit/LiveSplit.AutoSplitters

//RKD 2024 V2 Changelog: added the change to gametime prompt in the startup | used code from: SabulineHorizon Aquanox
//			 added option to disable the above

//If you understand the base routine please notify me. I don't understand it anymore, it became a messy patching hell.

state("MAIDFXVR_BLEU")
{
	//Debug: not used only for debugging
	long		GameCounter	:	0x3B2FE4			;
	//Base: memory adresses for the baselevel functionality 
	long		FrameCounter	:	0x225E80			;	
	string40	Level		:	0x1ECC5E			;
	byte		MenuState	:	"APMMXbvr.dll", 0xE66EC		;
	byte		SleepState	:	0x20EE10			;
	byte		SceneState	:	0x2107FC			;
	byte		BarnakLife	:	0x4371BE			;
	byte		SaveState	:	0x321b28 , 0x1c, 0x24c, 0x1c, 0x19c, 0x3c, 0xc0, 0x574;
	byte		Death		:	0x210800			;
	byte		Life		:	0x3456F8 , 0x8, 0x9C, 0x14, 0x1C, 0x4, 0x4, 0x18;
	float		ZCoord		:	0x356e64 , 0x0, 0x14, 0xC, 0x0, 0x330, 0x54, 0x8D0;
	//Split: memory adresses for the splits
	byte		ItemGatherBox	:	0x346F50 , 0x10, 0x0, 0xC, 0x910;
}

startup
{
	//For extra settings to enable in the GUI
	settings.Add("NoSplits", false, "Disable Splitting / Manual Splitting / only auto Start and Finish");
	settings.Add("NoGameTimePrompt", false, "Disable the prompt asking for the change to GameTime");
}

init
{
	//program & settings
	refreshRate = 47; // adjusted for HTTQ framerate, whether this is good or not: "I don't know"
	
	// Asks user to change to Game Time if LiveSplit is currently set to Real Time | credit: SabulineHorizon Aquanox | modified: RKD
	if (timer.CurrentTimingMethod == TimingMethod.RealTime && settings["NoGameTimePrompt"] == false){
		var timingMessage = MessageBox.Show (
			"This game uses Game Time as the main timing method.\n"+
			"LiveSplit is currently set to show Real Time (with loads)\n"+
			"Would you like to set the timing method to Game Time?",
			"LiveSplit | Hype The Time Quest",
			MessageBoxButtons.YesNo,MessageBoxIcon.Question
		);
		if (timingMessage == DialogResult.Yes){
			timer.CurrentTimingMethod = TimingMethod.GameTime;
		}
	}

	//baselevel variables
	vars.Vhoid = false; 			// this variable handles the endboss fight and divides it into two segments. One after the Vhoid Cutscene and one before.
	vars.LoadingStateHelper = false; 	// this variable ensures that the timer does not get stopped on savepedastels death animation and transitions
	vars.LoadingStateHelper2 = false; 	// this variable helps with the specific case in which you leave the saving pedastel and do a transition
	vars.wasDeadScreen = false; 		// this variable handles the exception when you restart after you died
	vars.wasDeadMenu = false;		// same as above, but after the barnak screen and in the menu
	vars.wasDeadMenuBlocker = false;	// same as above, but this blocks the timer after the first load after you got killed
	vars.initialRunStart = true;			// this variable handles not stopping timer on the first game start after starting the game
}

update
{
	//Debugging info, to view use DebugView/dbgview64.exe
	//print("Level:" + current.Level);
	//print("Levelold:" + old.Level);
	//print("FrameCount:" + current.FrameCounter.ToString());
	//print("GameTCount:" + current.GameCounter.ToString());
	//print("MenuState:" + current.MenuState.ToString());
	//print("SleepState:" + current.SleepState.ToString());
	//print("VhoidState:" + vars.Vhoid.ToString());
	//print("SaveState:" + current.SaveState.ToString());
	//print("LoadingState:" + vars.LoadingStateHelper.ToString());
	//print("LoadingState2:" + vars.LoadingStateHelper2.ToString());
	//print("Was Dead:" + vars.wasDeadScreen.ToString());
	//print("Was Menu:" + vars.wasDeadMenu.ToString());
	//print("Was Blocker:" + vars.wasDeadMenuBlocker.ToString());


	//Exception Handling
	//Vhoid & Barnak Double Cutscene Handling
	if (current.Level == @"toptower\toptower.ptx" && current.BarnakLife == 172){
		vars.Vhoid = true;
	}
	if (current.Level == @"toptower\toptower.ptx" && current.BarnakLife == 135){
		vars.Vhoid = false;
	}
	
	//Handling for using a pedastal and a loading transition afterwards, prevents timer not stopping
	if (old.Level != current.Level){
		vars.LoadingStateHelper2 = true;
	}
	if (current.SleepState == 0 && old.Level == current.Level){
		vars.LoadingStateHelper2 = false;
	}

	//Handling for getting killed and voiding out, prevents timer stop if you die and timer not stopping on the first load after
	if (vars.wasDeadScreen == false && current.Death == 0 && current.SleepState == 1 && (current.Life == 0 || current.ZCoord <= -300.0)){
		vars.wasDeadScreen = true;
		vars.LoadingStateHelper = true;
	}
	//if the deadscreen triggers randomly it gets turned of by this
	if (vars.wasDeadScreen == true && current.Level != old.Level && current.Level != @"fix.ptx"){
		vars.wasDeadScreen = false;
	}
	//turns into the next stage after barnak screen to menu
	if (vars.wasDeadScreen == true && current.Level == @"fix.ptx"){
		vars.wasDeadScreen = false;
		vars.wasDeadMenu = true;
	}
	//these next ones handle the first loading screen after death getting stopped
	if (vars.wasDeadMenu == true && current.SaveState == 1){
		vars.wasDeadMenu = true;
	}
	if (vars.wasDeadMenu == true && current.SaveState == 0 && current.Death == 1){
		vars.wasDeadMenuBlocker = true;
	}
	if ((vars.wasDeadMenuBlocker == true && current.SaveState == 0 && current.Death == 0) || (vars.wasDeadMenuBlocker == true && current.SaveState == 1 && current.Death == 1)){
		vars.wasDeadMenuBlocker = false;
	}
	if (vars.wasDeadMenu == true && old.FrameCounter != current. FrameCounter){
		vars.wasDeadMenu = false;
	}

	//Handling for the loading screen timer freeze
	if ((current.SaveState == 1 && current.SleepState == 1 && current.MenuState == 0 && vars.LoadingStateHelper2 == false)){
		vars.LoadingStateHelper = true;
	}
	if (current.SleepState == 1 && current.Death == 0  && current.MenuState == 0){
		vars.LoadingStateHelper = true;		
	}
	if ((current.SaveState == 1 && current.SleepState == 1 && current.MenuState == 0 && vars.LoadingStateHelper2 == true) || (current.SaveState == 1 && current.SleepState == 0 && current.MenuState == 0) || (current.SaveState == 0)){
		vars.LoadingStateHelper = false;
	}

	//This handles the not stopping timer on the first run started
	if (vars.initialRunStart == true && current.SceneState == 1){
	vars.initialRunStart = false;
	}
}

start
{
	//The timer start triggers if you progress from the loading screen to Manoir I, in theory it should wrongly start if you load to Manoir 1 from the loading screen. A fix has barely no use and I'm to lazy.
	if (old.Level == @"fix.ptx" && current.Level == @"manoir\manoir.ptx"){
		vars.Vhoid = false;
		return true;
	}
}

isLoading
{
	//This is only the functional bit of the loading screen timer stop logic. Exception Handling for dying and loading is in the update routine
	if ((current.SleepState == 1 && current.MenuState == 0 && current.Level != @"fix.ptx" && vars.LoadingStateHelper == false && vars.wasDeadScreen == false) || (vars.wasDeadMenuBlocker == true) || (vars.initialRunStart == true)){
		return true;
	}
	return false;
}

reset
{
	//This does the exact same as start and with that restarts the timer if you press start new game from the main menu, does not work from the ingame menu, still lazy.
	if (old.Level == @"fix.ptx" && current.Level == @"manoir\manoir.ptx"){
		return true;
	}
}

split
{
	//This if is responsible for all splits. Can be disabled through the settings.
	if (current.ItemGatherBox != old.ItemGatherBox && old.ItemGatherBox == 0 && settings["NoSplits"]==false){
		return true;
	}
	//Barnak Split
	if(current.Level == @"toptower\toptower.ptx" && current.SceneState == 1 && current.BarnakLife <= 70 && vars.Vhoid == false){
		return true;
	}
}
