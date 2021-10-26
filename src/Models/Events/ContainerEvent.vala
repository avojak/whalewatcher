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

public class WhaleWatcher.Models.Event.ContainerEvent : WhaleWatcher.Models.DockerEngineEvent {

    public const string TYPE = "container";

    public enum Action {

        ATTACH,
        COMMIT,
        COPY,
        CREATE,
        DESTROY,
        DETACH,
        DIE,
        EXEC_CREATE,
        EXEC_DETACH,
        EXEC_START,
        EXEC_DIE,
        EXPORT,
        HEALTH_STATUS,
        KILL,
        OOM,
        PAUSE,
        RENAME,
        RESIZE,
        RESTART,
        START,
        STOP,
        TOP,
        UNPAUSE,
        UPDATE,
        PRUNE;

        public static Action get_value_by_short_name (string short_name) {
            switch (short_name) {
                case "attach":
                    return ATTACH;
                case "commit":
                    return COMMIT;
                case "copy":
                    return COPY;
                case "create":
                    return CREATE;
                case "destroy":
                    return DESTROY;
                case "detach":
                    return DETACH;
                case "die":
                    return DIE;
                case "exec_create":
                    return EXEC_CREATE;
                case "exec_detach":
                    return EXEC_DETACH;
                case "exec_start":
                    return EXEC_START;
                case "exec_die":
                    return EXEC_DIE;
                case "export":
                    return EXPORT;
                case "health_status":
                    return HEALTH_STATUS;
                case "kill":
                    return KILL;
                case "oom":
                    return OOM;
                case "pause":
                    return PAUSE;
                case "rename":
                    return RENAME;
                case "resize":
                    return RESIZE;
                case "restart":
                    return RESTART;
                case "start":
                    return START;
                case "stop":
                    return STOP;
                case "top":
                    return TOP;
                case "unpause":
                    return UNPAUSE;
                case "update":
                    return UPDATE;
                case "prune":
                    return PRUNE;
                default:
                    assert_not_reached ();
            }
        }

    }

    //  public ContainerEvent (Action action) {
    //      Object (
    //          action: action
    //      );
    //  }

    public static WhaleWatcher.Models.Event.ContainerEvent from_json (Json.Object json) {
        WhaleWatcher.Models.DockerEngineEvent obj = new WhaleWatcher.Models.Event.ContainerEvent ();
        WhaleWatcher.Models.DockerEngineEvent.parse_json (json, ref obj);
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "Action":
                    ((WhaleWatcher.Models.Event.ContainerEvent) obj).action = Action.get_value_by_short_name (json.get_string_member (name));
                    break;
                default:
                    //  warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj as WhaleWatcher.Models.Event.ContainerEvent;
    }

    public Action action { get; set; }

}