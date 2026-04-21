package helptree.examples;

import helptree.HelpTree;
import helptree.HelpTree.Config;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

@Command(name = "deep", description = "A deeply nested CLI example (3 levels)")
public class Deep implements Runnable {

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

    @Command(name = "server", description = "Server management")
    static class ServerCmd implements Runnable {
        @Option(names = {"--verbose"}, description = "Verbose output")
        boolean verbose;

        @Command(name = "config", description = "Configuration commands")
        static class ConfigCmd implements Runnable {
            @Option(names = {"--verbose"}, description = "Verbose output")
            boolean verbose;

            @Command(name = "get", description = "Get a config value")
            static class GetCmd implements Runnable {
                @Option(names = {"--verbose"}, description = "Verbose output")
                boolean verbose;
                @Parameters(paramLabel = "KEY", description = "Config key")
                String key;
                public void run() {}
            }

            @Command(name = "set", description = "Set a config value")
            static class SetCmd implements Runnable {
                @Option(names = {"--verbose"}, description = "Verbose output")
                boolean verbose;
                @Parameters(paramLabel = "KEY", description = "Config key")
                String key;
                @Parameters(paramLabel = "VALUE", description = "Config value")
                String value;
                public void run() {}
            }

            @Command(name = "reload", description = "Reload configuration")
            static class ReloadCmd implements Runnable {
                @Option(names = {"--verbose"}, description = "Verbose output")
                boolean verbose;
                public void run() {}
            }

            public void run() {}
        }

        @Command(name = "db", description = "Database commands")
        static class DbCmd implements Runnable {
            @Command(name = "migrate", description = "Run migrations")
            static class MigrateCmd implements Runnable { public void run() {} }
            @Command(name = "seed", description = "Seed the database")
            static class SeedCmd implements Runnable { public void run() {} }
            @Command(name = "backup", description = "Backup the database")
            static class BackupCmd implements Runnable { public void run() {} }
            public void run() {}
        }

        public void run() {}
    }

    @Command(name = "client", description = "Client operations")
    static class ClientCmd implements Runnable {
        @Option(names = {"--verbose"}, description = "Verbose output")
        boolean verbose;

        @Command(name = "auth", description = "Authentication commands")
        static class AuthCmd implements Runnable {
            @Command(name = "login", description = "Log in")
            static class LoginCmd implements Runnable { public void run() {} }
            @Command(name = "logout", description = "Log out")
            static class LogoutCmd implements Runnable { public void run() {} }
            @Command(name = "whoami", description = "Show current user")
            static class WhoamiCmd implements Runnable { public void run() {} }
            public void run() {}
        }

        @Command(name = "request", description = "HTTP request commands")
        static class RequestCmd implements Runnable {
            @Option(names = {"--verbose"}, description = "Verbose output")
            boolean verbose;

            @Command(name = "get", description = "Send a GET request")
            static class GetCmd implements Runnable {
                @Option(names = {"--verbose"}, description = "Verbose output")
                boolean verbose;
                @Parameters(paramLabel = "PATH", description = "Request path")
                String path;
                public void run() {}
            }

            @Command(name = "post", description = "Send a POST request")
            static class PostCmd implements Runnable {
                @Option(names = {"--verbose"}, description = "Verbose output")
                boolean verbose;
                @Parameters(paramLabel = "PATH", description = "Request path")
                String path;
                public void run() {}
            }

            public void run() {}
        }

        public void run() {}
    }

    public void run() {}

    public static void main(String[] args) {
        Deep deep = new Deep();
        CommandLine cmd = new CommandLine(deep);

        CommandLine server = new CommandLine(new ServerCmd());
        CommandLine config = new CommandLine(new ServerCmd.ConfigCmd());
        config.addSubcommand("get", new CommandLine(new ServerCmd.ConfigCmd.GetCmd()));
        config.addSubcommand("set", new CommandLine(new ServerCmd.ConfigCmd.SetCmd()));
        config.addSubcommand("reload", new CommandLine(new ServerCmd.ConfigCmd.ReloadCmd()));
        server.addSubcommand("config", config);
        CommandLine db = new CommandLine(new ServerCmd.DbCmd());
        db.addSubcommand("migrate", new CommandLine(new ServerCmd.DbCmd.MigrateCmd()));
        db.addSubcommand("seed", new CommandLine(new ServerCmd.DbCmd.SeedCmd()));
        db.addSubcommand("backup", new CommandLine(new ServerCmd.DbCmd.BackupCmd()));
        server.addSubcommand("db", db);
        cmd.addSubcommand("server", server);

        CommandLine client = new CommandLine(new ClientCmd());
        CommandLine auth = new CommandLine(new ClientCmd.AuthCmd());
        auth.addSubcommand("login", new CommandLine(new ClientCmd.AuthCmd.LoginCmd()));
        auth.addSubcommand("logout", new CommandLine(new ClientCmd.AuthCmd.LogoutCmd()));
        auth.addSubcommand("whoami", new CommandLine(new ClientCmd.AuthCmd.WhoamiCmd()));
        client.addSubcommand("auth", auth);
        CommandLine request = new CommandLine(new ClientCmd.RequestCmd());
        request.addSubcommand("get", new CommandLine(new ClientCmd.RequestCmd.GetCmd()));
        request.addSubcommand("post", new CommandLine(new ClientCmd.RequestCmd.PostCmd()));
        client.addSubcommand("request", request);
        cmd.addSubcommand("client", client);

        Config cfg = HelpTree.extractConfig(args);
        if (cfg.helpTree) {
            var tree = HelpTree.fromPicocli(cmd);
            tree = HelpTree.resolvePath(tree, cfg.path);
            System.out.println(HelpTree.render(tree, cfg));
            return;
        }

        int exitCode = cmd.execute(cfg.remainingArgs.toArray(new String[0]));
        System.exit(exitCode);
    }
}
