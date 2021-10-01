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

public class WhaleWatcher.Util.JsonUtils {

    public static Json.Object? get_json_object (string? json_data) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (json_data);
            return parser.get_root ().get_object ();
        } catch (Error e) {
            warning (e.message);
            return null;
        }
    }

    public static Gee.List<GLib.Object>? parse_json_array (string? json_data, JsonDeserializer deserializer) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (json_data);
            var root_array = parser.get_root ().get_array ();
            var results = new Gee.ArrayList<GLib.Object> ();
            foreach (var item in root_array.get_elements ()) {
                results.add (deserializer (item.get_object ()));
            }
            return results;
        } catch (Error e) {
            warning (e.message);
            return null;
        }
    }

    public static GLib.Object? parse_json_obj (string? json_data, JsonDeserializer deserializer) {
        Json.Object? root_object = get_json_object (json_data);
        return deserializer (root_object);
    }

    public delegate GLib.Object? JsonDeserializer (Json.Object? json_obj);

}