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

public class WhaleWatcher.Models.DockerVersion : GLib.Object {

    public class Platform : GLib.Object {

        public string name { set; get; }

        public string to_string () {
            StringBuilder sb = new StringBuilder ();
            sb.append_printf ("name = %s\n", name);
            return (owned) sb.str;
        }

        public static WhaleWatcher.Models.DockerVersion.Platform from_json (Json.Object json) {
            var obj = new WhaleWatcher.Models.DockerVersion.Platform ();
            foreach (unowned string name in json.get_members ()) {
                switch (name) {
                    case "Name":
                        obj.name = json.get_string_member (name);
                        break;
                    default:
                        warning ("Unsupported attribute: %s", name);
                        break;
                }
            }
            return obj;
        }

    }

    public class Component : GLib.Object {

        public string name { set; get; }
        public string version { set; get; }
        public Gee.Map<string, string> details { set; get; }

        public string to_string () {
            StringBuilder sb = new StringBuilder ();
            sb.append_printf ("name = %s\n", name);
            sb.append_printf ("version = %s\n", version);
            sb.append_printf ("details = %s\n", "TODO");
            return (owned) sb.str;
        }

        public static WhaleWatcher.Models.DockerVersion.Component from_json (Json.Object json) {
            var obj = new WhaleWatcher.Models.DockerVersion.Component ();
            foreach (unowned string name in json.get_members ()) {
                switch (name) {
                    case "Name":
                        obj.name = json.get_string_member (name);
                        break;
                    case "Version":
                        obj.version = json.get_string_member (name);
                        break;
                    case "Details":
                        obj.details = new Gee.HashMap<string, string> ();
                        var details = json.get_object_member (name);
                        foreach (unowned string detail_name in details.get_members ()) {
                            obj.details.set (detail_name, details.get_string_member (detail_name));
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

    public Platform platform { set; get; }
    public Gee.List<Component> components { set; get; }
    public string version { set; get; }
    public string api_version { set; get; }
    public string min_api_version { set; get; }
    public string git_commit { set; get; }
    public string go_version { set; get; }
    public string os { set; get; }
    public string arch { set; get; }
    public string kernel_version { set; get; }
    public string build_time { set; get; }

    public static WhaleWatcher.Models.DockerVersion from_json (Json.Object json) {
        var obj = new WhaleWatcher.Models.DockerVersion ();
        foreach (unowned string name in json.get_members ()) {
            switch (name) {
                case "Platform":
                    obj.platform = Platform.from_json (json.get_object_member (name));
                    break;
                case "Components":
                    obj.components = new Gee.ArrayList<Component> ();
                    json.get_array_member (name).foreach_element ((array, index_, element_node) => {
                        obj.components.add (Component.from_json (element_node.get_object ()));
                    });
                    break;
                case "Version":
                    obj.version = json.get_string_member (name);
                    break;
                case "ApiVersion":
                    obj.api_version = json.get_string_member (name);
                    break;
                case "MinAPIVersion":
                    obj.min_api_version = json.get_string_member (name);
                    break;
                case "GitCommit":
                    obj.git_commit = json.get_string_member (name);
                    break;
                case "GoVersion":
                    obj.go_version = json.get_string_member (name);
                    break;
                case "Os":
                    obj.os = json.get_string_member (name);
                    break;
                case "Arch":
                    obj.arch = json.get_string_member (name);
                    break;
                case "KernelVersion":
                    obj.kernel_version = json.get_string_member (name);
                    break;
                case "BuildTime":
                    obj.build_time = json.get_string_member (name);
                    break;
                default:
                    warning ("Unsupported attribute: %s", name);
                    break;
            }
        }
        return obj;
    }

    public string to_string () {
        StringBuilder sb = new StringBuilder ();
        sb.append_printf ("platform = %s\n", platform.to_string ());
        sb.append_printf ("components = %s\n", components.get (0).to_string ());
        //  sb.append_printf ("version = %s\n", version);
        //  sb.append_printf ("api_version = %s\n", api_version);
        return (owned) sb.str;
    }

}