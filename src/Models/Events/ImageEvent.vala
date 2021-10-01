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

public class WhaleWatcher.Models.Event.ImageEvent : WhaleWatcher.Models.DockerEngineEvent {

    public const string TYPE = "image";

    public enum Action {

        DELETE,
        IMPORT,
        LOAD,
        PULL,
        PUSH,
        SAVE,
        TAG,
        UNTAG,
        PRUNE;

        public static Action get_value_by_short_name (string short_name) {
            switch (short_name) {
                case "delete":
                    return DELETE;
                case "import":
                    return IMPORT;
                case "load":
                    return LOAD;
                case "pull":
                    return PULL;
                case "push":
                    return PUSH;
                case "save":
                    return SAVE;
                case "tag":
                    return TAG;
                case "untag":
                    return UNTAG;
                case "prune":
                    return PRUNE;
                default:
                    assert_not_reached ();
            }
        }

    }

    //  public ImageEvent (Action action) {
    //      Object (
    //          action: action
    //      );
    //  }

    public static WhaleWatcher.Models.Event.ImageEvent from_json (Json.Object json) {
        WhaleWatcher.Models.DockerEngineEvent obj = new WhaleWatcher.Models.Event.ImageEvent ();
        WhaleWatcher.Models.DockerEngineEvent.parse_json (json, ref obj);
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "Action":
                    ((WhaleWatcher.Models.Event.ImageEvent) obj).action = Action.get_value_by_short_name (json.get_string_member (name));
                    break;
                default:
                    //  warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj as WhaleWatcher.Models.Event.ImageEvent;
    }

    public Action action { get; set; }

}