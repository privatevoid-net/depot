require ["variables", "envelope", "fileinto", "subaddress", "mailbox"];

if envelope :matches :detail "to" "*" {
	set :lower :upperfirst "name" "''${1}";
}

if not string :is "''${name}" "" {
	fileinto :create "Plus/''${name}";
}
