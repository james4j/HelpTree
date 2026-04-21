package helptree;

import java.util.List;

public class TreeCommand {
    public final String name;
    public final String description;
    public final boolean hidden;
    public final List<TreeOption> options;
    public final List<TreeArgument> arguments;
    public final List<TreeCommand> subcommands;

    public TreeCommand(String name, String description, boolean hidden,
                       List<TreeOption> options, List<TreeArgument> arguments,
                       List<TreeCommand> subcommands) {
        this.name = name;
        this.description = description;
        this.hidden = hidden;
        this.options = options;
        this.arguments = arguments;
        this.subcommands = subcommands;
    }
}
