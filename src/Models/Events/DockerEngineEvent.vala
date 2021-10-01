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

public abstract class WhaleWatcher.Models.DockerEngineEvent : GLib.Object {

    //  public DockerEngineEvent (T action) {
    //      Object (
    //          action: action
    //      );
    //  }

    public class Actor : GLib.Object {

        public string id { set; get; }
        public Gee.Map<string, string> attributes { set; get; }

        public static WhaleWatcher.Models.DockerEngineEvent.Actor from_json (Json.Object json) {
            var obj = new WhaleWatcher.Models.DockerEngineEvent.Actor ();
            foreach (unowned string name in json.get_members ()) {
                switch (name) {
                    case "ID":
                        obj.id = json.get_string_member (name);
                        break;
                    case "Attributes":
                        obj.attributes = new Gee.HashMap<string, string> ();
                        Json.Object attributes_obj = json.get_object_member (name);
                        foreach (var member in attributes_obj.get_members ()) {
                            obj.attributes.set (member, attributes_obj.get_string_member (member));
                        }
                        break;
                    default:
                        warning ("Unsupported attribute: %s", name);
                        break;
                }
            }
            return obj;
        }

    }

    protected static WhaleWatcher.Models.DockerEngineEvent parse_json (Json.Object json, ref WhaleWatcher.Models.DockerEngineEvent obj) {
        //  var type = json.get_string_member ("Type");
        //  var action = json.get_string_member ("Action");
        //  WhaleWatcher.Models.DockerEngineEvent<T> obj = null;
        //  switch (type) {
        //      case "image":
        //          obj = new WhaleWatcher.Models.DockerEngineEvent<WhaleWatcher.Models.Event.ImageEvent.Action> ();
        //          obj.action = WhaleWatcher.Models.Event.ImageEvent.Action.get_value_by_short_name (action);
        //          break;
        //      default:
        //          break;
        //  }
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "time":
                    obj.time = json.get_double_member (name);
                    break;
                case "Actor":
                    obj.actor = WhaleWatcher.Models.DockerEngineEvent.Actor.from_json (json.get_object_member (name));
                    break;
                //  case "Action":
                //      obj.action = json.get_string_member (name);
                //      break;
                default:
                    //  warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj;
    }

    public double time { set; get; }
    public Actor actor { get; set; }
    //  public T action { get; set; }

}