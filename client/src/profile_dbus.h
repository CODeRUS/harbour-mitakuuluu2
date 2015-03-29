
/******************************************************************************
** This file is part of profile-qt
**
** Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
**
** Contact: Sakari Poussa <sakari.poussa@nokia.com>
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**
** Redistributions of source code must retain the above copyright notice,
** this list of conditions and the following disclaimer. Redistributions in
** binary form must reproduce the above copyright notice, this list of
** conditions and the following disclaimer in the documentation  and/or
** other materials provided with the distribution.
**
** Neither the name of Nokia Corporation nor the names of its contributors
** may be used to endorse or promote products derived from this software 
** without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
** THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
** PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
** CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
** EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
** PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
** OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
** WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
** OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
** ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
******************************************************************************/

#ifndef PROFILE_DBUS_H_
# define PROFILE_DBUS_H_

/** @name DBus Daemon
 */

/*@{*/

/**
 * Profile daemon DBus service.
 **/
# define PROFILED_SERVICE "com.nokia.profiled"

/**
 * Profile daemon DBus object path.
 **/
# define PROFILED_PATH "/com/nokia/profiled"

/**
 * Profile daemon DBus method call and signal interface.
 **/
# define PROFILED_INTERFACE "com.nokia.profiled"

/*@}*/

/** @name DBus Methods
 */

/*@{*/

/**
 * Get active profile name.
 *
 * @param n/a
 * @returns profile : STRING
 **/
# define PROFILED_GET_PROFILE  "get_profile"

/**
 * Check existance of profile name.
 *
 * @param profile : STRING
 *
 * @returns exists : BOOLEAN
 **/
# define PROFILED_HAS_PROFILE  "has_profile"

/**
 * Set active profile name.
 *
 * @param profile : STRING
 *
 * @returns success : BOOLEAN
 **/
# define PROFILED_SET_PROFILE  "set_profile"

/**
 * Get available profiles.
 *
 * @param n/a
 *
 * @returns profiles : ARRAY of STRING
 **/
# define PROFILED_GET_PROFILES "get_profiles"

/**
 * Get available keys.
 *
 * @param n/a
 *
 * @returns keys : ARRAY of STRING
 **/
# define PROFILED_GET_KEYS     "get_keys"

/**
 * Get profile value.
 *
 * @param profile : STRING
 * @param key     : STRING
 *
 * @returns value : STRING
 **/
# define PROFILED_GET_VALUE    "get_value"

/**
 * Check existance of value.
 *
 * @param key : STRING
 *
 * @returns exists : BOOLEAN
 **/
# define PROFILED_HAS_VALUE    "has_value"

/**
 * Check if value can be modified.
 *
 * @param key : STRING
 *
 * @returns writable : BOOLEAN
 **/
# define PROFILED_IS_WRITABLE  "is_writable"

/**
 * Set profile value.
 *
 * @param   profile : STRING
 * @param   key     : STRING
 * @param   val     : STRING
 *
 * @returns success : BOOLEAN
 **/
# define PROFILED_SET_VALUE    "set_value"

/**
 * Get type of profile value.
 *
 * @param   profile : STRING
 * @param   key     : STRING
 *
 * @returns type    : STRING
 **/
# define PROFILED_GET_TYPE     "get_type"

/**
 * Get all profile values.
 *
 * @param   profile : STRING
 *
 * @returns values : ARRAY of STRUCT
 *         <br> key  : STRING
 *         <br> val  : STRING
 *         <br> type : STRING
 **/
# define PROFILED_GET_VALUES   "get_values"

/*@}*/

/** @name DBus Signals
 */

/*@{*/

/**
 * Signal emitted after changes to profile data
 *
 * @param changed : BOOLEAN
 * @param active  : BOOLEAN
 * @param profile : STRING
 * @param values  : ARRAY of STRUCT
 *         <br> key  : STRING
 *         <br> val  : STRING
 *         <br> type : STRING
 **/
# define PROFILED_CHANGED      "profile_changed"

/*@}*/

#endif
