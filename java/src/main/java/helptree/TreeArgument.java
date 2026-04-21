package helptree;

public class TreeArgument {
    public final String name;
    public final String description;
    public final boolean required;
    public final boolean hidden;

    public TreeArgument(String name, String description, boolean required, boolean hidden) {
        this.name = name;
        this.description = description;
        this.required = required;
        this.hidden = hidden;
    }
}
