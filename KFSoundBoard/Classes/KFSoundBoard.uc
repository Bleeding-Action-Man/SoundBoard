//=============================================================================
// Play custom sounds with mutate commands
// Made by Vel-San @ https://steamcommunity.com/id/Vel-San/
//=============================================================================

class KFSoundBoard extends Mutator Config(SoundBoardConfig);

#exec OBJ LOAD FILE=SoundBoardSND.uax

// Config Vars
var() config bool bDebug, bNotifyOnSoundUsed;
var() config int iDelay, iTimeOut;
var() config string sPlaySoundCMD;

// Vars
var string sLastSoundPlayedBy;
var int iLastPlayedAt, iPlayedCount;

// Sound Declaration Struct
struct CS
{
  var config string Sound; // Name of sound in the SoundPack, e.g. XX.YY
  var config string SoundTag; // Tag for human readbility, doesn't affect anything
  var config string SoundBind; // Bind to be used with mutate, e.g. mutate meow
};
var() config array<CS> SoundList; // SoundsList

// Colors from Config
struct ColorRecord
{
  var config string ColorName; // Color name, for comfort
  var config string ColorTag; // Color tag
  var config Color Color; // RGBA values
};
var() config array<ColorRecord> ColorList; // Color list


// Initialization
function PostBeginPlay()
{
  // Generate Default Config File, keep commented unless you want to generate one yourself
  // SaveConfig();

  // Force client to download SoundPack
  AddToPackageMap("SoundBoardSND.uax");

  // Initialize
  iPlayedCount = 1;

  if(bDebug)
  {
    MutLog("-----|| Found [" $SoundList.Length$ "] Sounds in Config File ||-----");
  }
}

function Timer()
{
  iLastPlayedAt = 0;
}

function Mutate(string command, PlayerController Sender)
{
  local string PN, PID, WelcomeMSG, DelayMSG, TimeoutMSG, TotalSoundsMSG, UsageMSG, PrintSoundsMSG;
  local array<string> SplitCMD;

  PN = Sender.PlayerReplicationInfo.PlayerName;
  PID = Sender.GetPlayerIDHash();

  if(bDebug)
	{
		MutLog("-----|| DEBUG - '" $command$ "' accessed by: " $PN$ " | PID: " $PID$  " ||-----");
	}

  SplitStringToArray(SplitCMD, command, " ");

  if(command ~= "sb help" || command ~= "soundboard help")
	{
		WelcomeMSG = "%yYou are viewing Sound-Board Help, below are the commands you can use";
		DelayMSG = "%bDelay between sounds (seconds): %w" $iDelay;
    TimeoutMSG = "%bPlayers get timed-out after %t" $iTimeOut$ "%w consecutive sound triggers";
		TotalSoundsMSG = "%bTotal Sounds: %w" $SoundList.Length;
		UsageMSG = "%bUsage: %wmutate " $sPlaySoundCMD$ " %tXXX%w | XXX is the tag of the sound you want to play";
    PrintSoundsMSG = "%bTo view all available sounds: %wmutate %t!sounds %wOR %t!snds";

    SetColor(WelcomeMSG);
		SetColor(DelayMSG);
    SetColor(TimeoutMSG);
		SetColor(TotalSoundsMSG);
		SetColor(UsageMSG);
		SetColor(PrintSoundsMSG);

    Sender.ClientMessage(WelcomeMSG);
		Sender.ClientMessage(DelayMSG);
		Sender.ClientMessage(TimeoutMSG);
		Sender.ClientMessage(TotalSoundsMSG);
		Sender.ClientMessage(UsageMSG);
		Sender.ClientMessage(PrintSoundsMSG);

		return;
	}

  if(command ~= "!sounds" || command ~= "!snds" )
  {
    PrintAllSounds(SoundList, Sender);
  }

  if(Left(command, Len(sPlaySoundCMD)) ~= sPlaySoundCMD)
  {
    CheckSoundAndPlay(SplitCMD[1], SoundList, PN, Sender);
  }

  if (NextMutator != None ) NextMutator.Mutate(command, Sender);
}

final function SplitStringToArray(out array<string> Parts, string Source, string Delim)
{
  Split(Source, Delim, Parts);
}

function ServerMessage(string Msg)
{
	local Controller C;
	local PlayerController PC;
	for (C = Level.ControllerList; C != none; C = C.nextController)
	{
		PC = PlayerController(C);
		if (PC != none)
		{
			SetColor(Msg);
			PC.ClientMessage(Msg);
		}
	}
}

function CriticalServerMessage(string Msg)
{
	local Controller C;
	local PlayerController PC;
	for (C = Level.ControllerList; C != none; C = C.nextController)
	{
		PC = PlayerController(C);
		if (PC != none)
		{
			SetColor(Msg);
			PC.ClientMessage(Msg, 'CriticalEvent');
		}
	}
}

function bool CheckSoundAndPlay(string SoundToPlay, array<CS> ListOfSounds, string PlayerName, PlayerController TmpPC)
{
  local int i;
  local string SoundPlayedMSG, SpamMSG, SpamCountMSG;
  local sound SoundEffect;

  SpamMSG = "%b" $PlayerName$ "%w, Please don't spam - There's a %t" $iDelay$ "%w seconds delay between sounds!";
  SpamCountMSG = "%b" $PlayerName$ "%w, You can play %t" $iTimeOut$ " %wconsecutive voices before you are timed out!";

  for(i=0; i<ListOfSounds.Length; i++)
  {
    if(ListOfSounds[i].Sound != "" && ListOfSounds[i].SoundTag != "" && ListOfSounds[i].SoundBind != "")
    {
      if (SoundToPlay ~= ListOfSounds[i].SoundBind)
      {
		    if(bDebug) MutLog("-----|| DEBUG - Found: Bind [" $ListOfSounds[i].SoundBind$ "] | Tag [" $ListOfSounds[i].SoundTag$ "] ||-----");
        SoundEffect = sound(DynamicLoadObject(ListOfSounds[i].Sound, class'Sound'));
        if(bDebug) MutLog("-----|| DEBUG - Attempting to play: Sound [" $SoundEffect$ "] ||-----");
        SoundPlayedMSG = "%t" $ListOfSounds[i].SoundBind$ "%w! [" $PlayerName$ "]";
        if (SoundEffect != none)
        {
          if (iLastPlayedAt < (Level.TimeSeconds))
          {
            if(sLastSoundPlayedBy == PlayerName)
            {
              iPlayedCount += 1;
              if (iPlayedCount >= iTimeOut)
              {
                SetColor(SpamCountMSG);
                TmpPC.ClientMessage(SpamCountMSG);
                return false;
              }
            }
            else
            {
              iPlayedCount = 0;
            }
            if(bNotifyOnSoundUsed) ServerMessage(SoundPlayedMSG);
            PlaySoundEffect(ListOfSounds[i].Sound);
            iLastPlayedAt = Level.TimeSeconds + iDelay;
            sLastSoundPlayedBy = PlayerName;
            SetTimer(iDelay, false);
            return true;
          }
          else
          {
            SetColor(SpamMSG);
            TmpPC.ClientMessage(SpamMSG);
            return false;
          }
        }
      }
    }
  }
  if(bDebug) MutLog("-----|| DEBUG - Bind Not Found: [" $SoundToPlay$ "] ||-----");
  return false;
}

function PlaySoundEffect(string Sound)
{
  local Controller C;
  local sound SoundEffect;

  SoundEffect = sound(DynamicLoadObject(Sound, class'Sound'));
  for( C = Level.ControllerList; C != None; C = C.nextController )
	{
		if( C.IsA('PlayerController') && PlayerController(C).PlayerReplicationInfo.PlayerID != 0)
		{
			PlayerController(C).ClientPlaySound(SoundEffect);
		}
	}
}

function PrintAllSounds(array<CS> Sounds, PlayerController PC)
{
  local string TmpSoundMSG;
  local int i;
  for(i=0; i<Sounds.Length; i++)
  {
    if(Sounds[i].Sound != "" && Sounds[i].SoundTag != "" && Sounds[i].SoundBind != "")
    {
      TmpSoundMSG = "%wSound: %b" $Sounds[i].SoundTag$ "%w | Bind: %t" $Sounds[i].SoundBind;
      SetColor(TmpSoundMSG);
      PC.ClientMessage(TmpSoundMSG);
    }
  }
}

function TimeStampLog(coerce string s)
{
  log("["$Level.TimeSeconds$"s]" @ s, 'SoundBoard');
}

function MutLog(string s)
{
  log(s, 'SoundBoard');
}

/////////////////////////////////////////////////////////////////////////
// BELOW SECTION IS CREDITED FOR NikC //

// Apply Color Tags To Message
function SetColor(out string Msg)
{
  local int i;
  for(i=0; i<ColorList.Length; i++)
  {
    if(ColorList[i].ColorTag!="" && InStr(Msg, ColorList[i].ColorTag)!=-1)
    {
      ReplaceText(Msg, ColorList[i].ColorTag, FormatTagToColorCode(ColorList[i].ColorTag, ColorList[i].Color));
    }
  }
}

// Format Color Tag to ColorCode
function string FormatTagToColorCode(string Tag, Color Clr)
{
  Tag=Class'GameInfo'.Static.MakeColorCode(Clr);
  Return Tag;
}

function string RemoveColor(string S)
{
  local int P;
  P=InStr(S,Chr(27));
  While(P>=0)
  {
    S=Left(S,P)$Mid(S,P+4);
    P=InStr(S,Chr(27));
  }
  Return S;
}
//////////////////////////////////////////////////////////////////////

defaultproperties
{
  // Mandatory Vars
	GroupName = "KF-SoundBoard"
  FriendlyName = "Sound Board - v1.1"
  Description = "Play custom sounds with key binds / mutate commands; Made by Vel-San"

  // Config Vars
  bDebug = True
  bNotifyOnSoundUsed = True
  iDelay = 5
  iTimeOut = 3
  sPlaySoundCMD = "do"
}