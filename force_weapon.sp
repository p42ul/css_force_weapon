#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define WEAPON_NAME_MAX_LENGTH 16
#define NUM_WEAPONS 24

public Plugin myinfo =
{
	name		= "ForceWeapon",
	author		= "crumptkin",
	description = "Forces a single weapon",
	version		= "0.0.2",
	url			= "rumpus.club"
};

ConVar cvarWeaponT = null;
ConVar cvarWeaponCT = null;
ConVar cvarEnabled = null;
ConVar cvarWeaponAll = null;
ConVar cvarRandomize = null;

int randomWeaponIndex = 0;

static const char weapons[NUM_WEAPONS][WEAPON_NAME_MAX_LENGTH] =
{
	"weapon_glock",
	"weapon_usp",
	"weapon_p228",
	"weapon_deagle",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_galil",
	"weapon_ak47",
	"weapon_scout",
	"weapon_sg552",
	"weapon_awp",
	"weapon_g3sg1",
	"weapon_famas",
	"weapon_m4a1",
	"weapon_aug",
	"weapon_sg550",
	"weapon_mac10",
	"weapon_tmp",
	"weapon_mp5navy",
	"weapon_ump45",
	"weapon_p90",
	"weapon_m249"
};

public void OnPluginStart()
{
	cvarWeaponT = CreateConVar("sm_forceweapon_t", "weapon_mac10", "Forced weapon for Ts");
	cvarWeaponCT = CreateConVar("sm_forceweapon_ct", "weapon_tmp", "Forced weapon for CTs");
	cvarEnabled = CreateConVar("sm_forceweapon_enable", "1", "Whether ForceWeapon is enabled or not");
	cvarRandomize = CreateConVar("sm_forceweapon_randomize", "0", "If true, gives both Ts and CTs a random weapon");
	cvarWeaponAll = CreateConVar("sm_forceweapon_all", "", "Alias to set forced weapon for Ts and CTs");
	cvarWeaponAll.AddChangeHook(OnForceWeaponAllChange);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	randomWeaponIndex = GetRandomInt(0, WEAPON_NAME_MAX_LENGTH - 1);
	return Plugin_Continue;
}

public void OnForceWeaponAllChange(ConVar convar, char[] oldValue, char[] newValue)
{
	cvarWeaponT.SetString(newValue);
	cvarWeaponCT.SetString(newValue);
}

// This function is hooked automatically
public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	if (!cvarEnabled.BoolValue)
	{
		return Plugin_Continue;
	}
	PrintToChat(client, "Cannot buy while ForceWeapon is enabled!");
	return Plugin_Handled;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvarEnabled.BoolValue)
	{
		return Plugin_Continue;
	}
	int userId = event.GetInt("userid");
	int client = GetClientOfUserId(userId);
	int team = GetClientTeam(client);
	char weaponCt[WEAPON_NAME_MAX_LENGTH];
	char weaponT[WEAPON_NAME_MAX_LENGTH];
	cvarWeaponCT.GetString(weaponCt, WEAPON_NAME_MAX_LENGTH);
	cvarWeaponT.GetString(weaponT, WEAPON_NAME_MAX_LENGTH);

	StripAllWeapons(client);
	GivePlayerItem(client, "item_assaultsuit");

	
	if (cvarRandomize.BoolValue)
	{
		GivePlayerItem(client, weapons[randomWeaponIndex], 0);
		return Plugin_Handled;
	}
	if (CS_TEAM_CT == team)
	{
		GivePlayerItem(client, weaponCt, 0);
	}
	else if (CS_TEAM_T == team) {
		GivePlayerItem(client, weaponT, 0);
	}
	return Plugin_Handled;
}

void StripAllWeapons(int client)
{
	int entity;
	for (int i = 0; i <= 4; i++)
	{
		// Don't remove the knife; it's fun
		if (CS_SLOT_KNIFE == i)
		{
			continue;
		}
		entity = GetPlayerWeaponSlot(client, i);
		if (entity != -1)
		{
			RemovePlayerItem(client, entity);
			AcceptEntityInput(entity, "Kill");
		}
	}
}
