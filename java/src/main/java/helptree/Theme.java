package helptree;

public class Theme {
    public final Style command;
    public final Style options;
    public final Style description;

    public Theme(Style command, Style options, Style description) {
        this.command = command;
        this.options = options;
        this.description = description;
    }

    public static class Style {
        public final String emphasis;
        public final String colorHex;

        public Style(String emphasis, String colorHex) {
            this.emphasis = emphasis;
            this.colorHex = colorHex;
        }

        public String ansiPrefix() {
            StringBuilder sb = new StringBuilder();
            boolean hasCode = false;
            if ("bold".equals(emphasis) || "bold_italic".equals(emphasis)) {
                sb.append("1");
                hasCode = true;
            }
            if ("italic".equals(emphasis) || "bold_italic".equals(emphasis)) {
                if (hasCode) sb.append(";");
                sb.append("3");
                hasCode = true;
            }
            if (colorHex != null && !colorHex.isEmpty() && colorHex.startsWith("#") && colorHex.length() == 7) {
                int r = Integer.parseInt(colorHex.substring(1, 3), 16);
                int g = Integer.parseInt(colorHex.substring(3, 5), 16);
                int b = Integer.parseInt(colorHex.substring(5, 7), 16);
                if (hasCode) sb.append(";");
                sb.append("38;2;").append(r).append(";").append(g).append(";").append(b);
                hasCode = true;
            }
            return hasCode ? "\u001b[" + sb + "m" : "";
        }

        public String ansiSuffix() {
            return ansiPrefix().isEmpty() ? "" : "\u001b[0m";
        }

        public String wrap(String text) {
            String pre = ansiPrefix();
            return pre.isEmpty() ? text : pre + text + ansiSuffix();
        }
    }

    public static Theme defaultTheme() {
        return new Theme(
            new Style("bold", "#7ee7e6"),
            new Style("normal", null),
            new Style("italic", "#90a2af")
        );
    }

    public static Theme plainTheme() {
        return new Theme(
            new Style("normal", null),
            new Style("normal", null),
            new Style("normal", null)
        );
    }
}
