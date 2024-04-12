local ddb = import 'ddb.docker.libjsonnet';

# Gestion du DNS de dev
local domain_ext = std.extVar("core.domain.ext");
local domain_sub = std.extVar("core.domain.sub");
local domain = std.join('.', [domain_sub, domain_ext]);

local web_workdir = "/var/www/html";
local app_workdir = "/app";

# Objet de la base de données
local db = {
    password: 'formation',
    root_password: 'formation',
    user: self.password
};

ddb.Compose() {
    services: {
        php:    ddb.Build("php") +
                ddb.User() +
                ddb.Binary("composer", "/var/www/html", "composer") +
                ddb.Binary("php", "/var/www/html", "php") +
                ddb.Binary("rector", "/var/www/html", "/var/www/html/vendor/bin/rector") +
                ddb.Binary("phpcs", "/var/www/html", "/var/www/html/vendor/bin/phpcs")  +
                ddb.Binary("phpcbf", "/var/www/html", "/var/www/html/vendor/bin/phpcbf")  +
                ddb.Binary("symfony", "/var/www/html", "symfony") +
                ddb.Binary("robo", "/var/www/html", "/var/www/html/vendor/bin/robo") +
                (if ddb.env.is("dev") then ddb.XDebug() else {}) +
                {
                    volumes+: [
                        ddb.path.project + ":/var/www/html",
                        ddb.path.project + "/.docker/php/php.ini:/usr/local/etc/php/conf.d/php-config.ini",
                        ddb.path.project + "/.docker/php/msmtprc:/etc/msmtprc",
                        "php-composer-cache:/composer/cache",
                        "php-composer-vendor:/composer/vendor"
                    ]
                },
        db:     ddb.Build("db") +
                ddb.User() +
                ddb.Expose("3306") +
                ddb.Binary("mysql", app_workdir, "mysql  -hdb -uroot" + " -p" + db.root_password) +
                ddb.Binary("mysqldump", app_workdir, "mysqldump  -hdb -uroot" +  " -p" + db.root_password) +
                {
                    command+: '--max_allowed_packet=32505856',
                    environment+: {
                        "MYSQL_ROOT_PASSWORD": db.root_password,
                    },
                    volumes+: [
                        ddb.path.project + ":" + app_workdir,
                        "db:/var/lib/mysql",
                    ]
                },
        web:    ddb.Build("web") +
                ddb.VirtualHost("80", domain) +
                {
                    volumes+: [
                        ddb.path.project + ":" + web_workdir,
                        ddb.path.project + "/.docker/web/apache.conf:/usr/local/apache2/conf/custom/apache.conf",
                    ]
                },
        node:   ddb.Build("node") +
                ddb.VirtualHost("3000", ddb.subDomain("live"), "live") +
                ddb.VirtualHost("6006", ddb.subDomain("ui"), "ui") +
                ddb.Binary("conventional-changelog", app_workdir, "conventional-changelog", "--label traefik.enable=false") +
                ddb.Binary("node", app_workdir, "node", exe=true) +
                ddb.Binary("webpack", app_workdir, "webpack", exe=true) +
                ddb.Binary("start-storybook", app_workdir, "storybook", exe=true) +
                ddb.Binary("webpack-cli", app_workdir, "webpack-cli", exe=true) +
                ddb.Binary("npm", app_workdir, "npm", exe=true) +
                ddb.Binary("npx", app_workdir, "npx", exe=true) +
                ddb.Binary("yarn", "/app", "yarn", exe=true) +
                {
                    volumes+: [
                        ddb.path.project + ":" + app_workdir,
                        "node-cache:/home/node/.cache",
                        "node-npm-packages:/home/node/.npm-packages"
                    ],
                    tty: true
                },
        [if ddb.env.is("dev") then "mail"]:
                ddb.Build("mail") +
                ddb.Expose(25) +
                ddb.VirtualHost("80", std.join('.', ["mail", domain]), "mail")
    }
}
