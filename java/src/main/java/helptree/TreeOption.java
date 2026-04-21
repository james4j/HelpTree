package helptree;

public class TreeOption {
    public final String name;
    public final String shortName;
    public final String longName;
    public final String description;
    public final boolean required;
    public final boolean takesValue;
    public final boolean hidden;

    public TreeOption(String name, String shortName, String longName, String description,
                      boolean required, boolean takesValue, boolean hidden) {
        this.name = name;
        this.shortName = shortName;
        this.longName = longName;
        this.description = description;
        this.required = required;
        this.takesValue = takesValue;
        this.hidden = hidden;
    }
}
