package helptree.examples;

import helptree.HelpTree;
import helptree.HelpTree.Config;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

@Command(name = "basic", description = "A basic example CLI with nested subcommands")
public class Basic implements Runnable {

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

    @Command(name = "project", description = "Manage projects")
    static class ProjectCmd implements Runnable {
        @Option(names = {"--verbose"}, description = "Verbose output")
        boolean verbose;

        @Command(name = "list", description = "List all projects")
        static class ListCmd implements Runnable {
            @Option(names = {"--verbose"}, description = "Verbose output")
            boolean verbose;
            public void run() {}
        }

        @Command(name = "create", description = "Create a new project")
        static class CreateCmd implements Runnable {
            @Option(names = {"--verbose"}, description = "Verbose output")
            boolean verbose;
            @Parameters(paramLabel = "NAME", description = "Project name")
            String name;
            public void run() {}
        }

        public void run() {}
    }

    @Command(name = "task", description = "Manage tasks")
    static class TaskCmd implements Runnable {
        @Option(names = {"--verbose"}, description = "Verbose output")
        boolean verbose;

        @Command(name = "list", description = "List all tasks")
        static class ListCmd implements Runnable {
            @Option(names = {"--verbose"}, description = "Verbose output")
            boolean verbose;
            public void run() {}
        }

        @Command(name = "done", description = "Mark a task as done")
        static class DoneCmd implements Runnable {
            @Option(names = {"--verbose"}, description = "Verbose output")
            boolean verbose;
            @Parameters(paramLabel = "ID", description = "Task ID")
            int id;
            public void run() {}
        }

        public void run() {}
    }

    public void run() {}

    public static void main(String[] args) {
        Basic basic = new Basic();
        CommandLine cmd = new CommandLine(basic);
        cmd.addSubcommand("project", new CommandLine(new ProjectCmd()));
        cmd.getSubcommands().get("project").addSubcommand("list", new CommandLine(new ProjectCmd.ListCmd()));
        cmd.getSubcommands().get("project").addSubcommand("create", new CommandLine(new ProjectCmd.CreateCmd()));
        cmd.addSubcommand("task", new CommandLine(new TaskCmd()));
        cmd.getSubcommands().get("task").addSubcommand("list", new CommandLine(new TaskCmd.ListCmd()));
        cmd.getSubcommands().get("task").addSubcommand("done", new CommandLine(new TaskCmd.DoneCmd()));

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
