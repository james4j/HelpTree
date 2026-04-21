package helptree.examples;

import helptree.HelpTree;
import helptree.HelpTree.Config;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

@Command(name = "hidden", description = "An example with hidden commands and flags")
public class Hidden implements Runnable {

    @Option(names = {"--help-tree"}, description = "Print a recursive command map derived from framework metadata")
    boolean helpTree;

    @Option(names = {"-L", "--tree-depth"}, description = "Limit --help-tree recursion depth (Unix tree -L style)")
    Integer treeDepth;

    @Option(names = {"-I", "--tree-ignore"}, description = "Exclude subtrees/commands from --help-tree output (repeatable)")
    String[] treeIgnore;

    @Option(names = {"-a", "--tree-all"}, description = "Include hidden subcommands in --help-tree output")
    boolean treeAll;

    @Option(names = {"--tree-output"}, description = "Output format (text or json)")
    String treeOutput;

    @Option(names = {"--tree-style"}, description = "Tree text styling mode (rich or plain)")
    String treeStyle;

    @Option(names = {"--tree-color"}, description = "Tree color mode (auto, always, never)")
    String treeColor;

    @Option(names = {"--verbose"}, description = "Verbose output")
    boolean verbose;

    @Option(names = {"--debug"}, description = "Enable debug mode", hidden = true)
    boolean debug;

    @Command(name = "list", description = "List items")
    static class ListCmd implements Runnable {
        public void run() {}
    }

    @Command(name = "show", description = "Show item details")
    static class ShowCmd implements Runnable {
        @Parameters(paramLabel = "ID", description = "Item ID")
        String id;
        public void run() {}
    }

    @Command(name = "admin", description = "Administrative commands", hidden = true)
    static class AdminCmd implements Runnable {
        @Command(name = "users", description = "List all users")
        static class UsersCmd implements Runnable { public void run() {} }
        @Command(name = "stats", description = "Show system stats")
        static class StatsCmd implements Runnable { public void run() {} }
        @Command(name = "secret", description = "Secret backdoor")
        static class SecretCmd implements Runnable { public void run() {} }
        public void run() {}
    }

    public void run() {}

    public static void main(String[] args) {
        Hidden hidden = new Hidden();
        CommandLine cmd = new CommandLine(hidden);
        cmd.addSubcommand("list", new ListCmd());
        cmd.addSubcommand("show", new ShowCmd());
        CommandLine admin = new CommandLine(new AdminCmd());
        admin.addSubcommand("users", new AdminCmd.UsersCmd());
        admin.addSubcommand("stats", new AdminCmd.StatsCmd());
        admin.addSubcommand("secret", new AdminCmd.SecretCmd());
        cmd.addSubcommand("admin", admin);

        Config config = HelpTree.extractConfig(args);
        if (config.helpTree) {
            var tree = HelpTree.fromPicocli(cmd);
            tree = HelpTree.resolvePath(tree, config.path);
            System.out.println(HelpTree.render(tree, config));
            return;
        }

        int exitCode = cmd.execute(config.remainingArgs.toArray(new String[0]));
        System.exit(exitCode);
    }
}
