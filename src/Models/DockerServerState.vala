/*
 * Copyright (c) 2021 Andrew Vojak (https://avojak.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Andrew Vojak <andrew.vojak@gmail.com>
 */

public class WhaleWatcher.Models.DockerServerState : GLib.Object {

    public enum State {

        OK,
        ERROR;

    }

    public string? message { get; set; }
    public State state { get; set; }

    public string to_string () {
        StringBuilder sb = new StringBuilder ();
        sb.append_printf ("state = %s\n", state.to_string ());
        sb.append_printf ("message = %s\n", message);
        return (owned) sb.str;
    }

    public static WhaleWatcher.Models.DockerServerState? from_json (Json.Object json) {
        if (json.has_member ("message")) {
            return new WhaleWatcher.Models.DockerServerState () {
                state = State.ERROR,
                message = json.get_string_member ("message")
            };
        }
        return null;
    }

}