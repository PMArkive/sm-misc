#if defined _connection_delay_included
 #endinput
#endif
#define _connection_delay_included

/**
 * Delays a client's connection for a specified amount of time.
 *
 * @param steamID       The Steam ID of the client to delay.
 * @param delayTime     The amount of time to delay the connection (in seconds).
 * @return              True if the delay was set, false if the client was already delayed.
 */
native bool CD_DelayClientConnection(const char[] steamID, float delayTime);

/**
 * Allows a previously delayed client to connect.
 *
 * @param steamID       The Steam ID of the client to allow.
 * @return              True if the client was allowed, false if the client was not delayed.
 */
native bool CD_AllowClientConnection(const char[] steamID);

/**
 * Checks if a client's connection is currently delayed.
 *
 * @param steamID       The Steam ID of the client to check.
 * @return              True if the client is delayed, false otherwise.
 */
native bool CD_IsClientDelayed(const char[] steamID);

/**
 * Called when a client's delayed connection is finally allowed.
 *
 * @param client        The client index.
 * @param steamID       The Steam ID of the client.
 */
forward void CD_OnClientDelayedConnect(int client, const char[] steamID);

public SharedPlugin __pl_connection_delay = 
{
    name = "connection_delay",
    file = "connection_delay.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_connection_delay_SetNTVOptional()
{
    MarkNativeAsOptional("CD_DelayClientConnection");
    MarkNativeAsOptional("CD_AllowClientConnection");
    MarkNativeAsOptional("CD_IsClientDelayed");
}
#endif