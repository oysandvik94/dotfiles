format_yay_output() {
	echo "$1" | grep -q "there is nothing to do" && exit 0

	table_start=$(echo "$1" | grep -n ":: [0-9]* packages to upgrade/install" | cut -d: -f1)
	table_end=$(echo "$1" | grep -n "==> Packages to exclude: " | cut -d: -f1)

	# Calculate necessary offset from start line
	table_start=$((table_start + 1))

	# Extract the table lines
	table_text=$(echo "$1" | tail -n +$table_start | head -n $(($table_end - $table_start)))

	# Basic output formatting
	echo "Package Name                Old Version  New Version"
	echo "--------------------------- -------- --------"
	echo "$table_text" | while read -r line; do
		IFS=' ' read -r -a parts <<<"$line"
		printf "%-27s %-8s %s\n" "${parts[1]}" "${parts[2]}" "${parts[4]}" # Print with some spacing
	done

}
