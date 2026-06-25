#!/usr/bin/env fish

# ==================================================
# CONFIGURATION
# ==================================================

set CONFIG_DIR ~/.config/translate
set CONFIG_FILE $CONFIG_DIR/config.fish

set DEFAULT_MODEL "kaelri/hy-mt2:1.8b"
set DEFAULT_MODE "id->en"

mkdir -p $CONFIG_DIR

# ==================================================
# LOAD CONFIG
# ==================================================

if test -f $CONFIG_FILE
	source $CONFIG_FILE
end

if not set -q MODEL
	set -g MODEL $DEFAULT_MODEL
end

if not set -q TRANSLATION_MODE
	set -g TRANSLATION_MODE $DEFAULT_MODE
end

# ==================================================
# SAVE CONFIG
# ==================================================

function save_config

	mkdir -p $CONFIG_DIR

	echo "set -g MODEL '$MODEL'" > $CONFIG_FILE
	echo "set -g TRANSLATION_MODE '$TRANSLATION_MODE'" >> $CONFIG_FILE

end

# ==================================================
# MODEL SELECTION
# ==================================================

function choose_model

	set models (ollama list | tail -n +2 | awk '{print $1}')

	if test (count $models) -eq 0
		echo "No Ollama models found."
		return 1
	end

	set selected_model (printf "%s\n" $models | gum choose)

	if test -z "$selected_model"
		set selected_model "kaelri/hy-mt2:1.8b"
	end

	set -g MODEL "$selected_model"

	save_config

end

# ==================================================
# LANGUAGE SELECTION
# ==================================================

function choose_language

	set -g TRANSLATION_MODE (gum choose \
		"id->en" \
		"en->id" 
	)

	save_config

end

# ==================================================
# TOGGLE
# ==================================================

function toggle_language

	switch "$TRANSLATION_MODE"

		case "id->en"
			set -g TRANSLATION_MODE "en->id"

		case "en->id"
			set -g TRANSLATION_MODE "id->en"

	end

	save_config

end

# ==================================================
# ARGUMENTS
# ==================================================

set choose_model_flag 0
set choose_language_flag 0

for arg in $argv

	switch $arg

		case "--choose-model" "-cm" "-m"
			set choose_model_flag 1

		case "--choose-language" "-cl" "-l"
			set choose_language_flag 1

	end

end

# ==================================================
# STARTUP MENUS
# ==================================================

if test $choose_model_flag -eq 1
	choose_model
end

if test $choose_language_flag -eq 1
	choose_language
end

# ==================================================
# BUILD PROMPT
# ==================================================


function build_prompt --argument-names mode text

	switch "$mode"

		case "id->en"
			set target_lang "English"

		case "en->id"
			set target_lang "Indonesia"

		case '*'
			set target_lang "English"

	end

	printf "%s" "
Translate the following text into $target_lang. Note that you should only output the translated result without any additional explanation:

$text
"

end

# ==================================================
# HEADER
# ==================================================

echo
echo "Translator Ready"
echo "Model : $MODEL"
echo "Mode  : $TRANSLATION_MODE"
echo
echo "Commands:"
echo "  /mode"
echo "  /lang"
echo "  /model"
echo "  /status"
echo "  /bye"
echo

# ==================================================
# MAIN LOOP
# ==================================================

while true

	read -P "[$TRANSLATION_MODE][$MODEL]> " text 

	test -z "$text"
	and continue

	switch "$text"

		case "/bye"
			break

		case "/status"
			
			echo
			echo "Model : $MODEL"
			echo "Mode  : $TRANSLATION_MODE"
			echo
			continue

		case "/lang"
			
			choose_language

			echo
			echo "Mode changed to: $TRANSLATION_MODE"
			echo

			continue

		case "/mode"

			toggle_language

			echo
			echo "Mode changed to: $TRANSLATION_MODE"
			echo

			continue

		case "/model"

			choose_model

			echo
			echo "Model changed to: $MODEL"
			echo

			continue

	end

	set prompt (build_prompt "$TRANSLATION_MODE" "$text")

	echo

	ollama run "$MODEL" "$prompt"

	echo

end

echo
echo "Goodbye!"
echo
