/** @type {import('tailwindcss').Config} */
export default {
	content: ["./src/**/*.{html,js,svelte,ts}"],
	theme: {
		extend: {
			colors: {
				"dark-gray": "#222325",
				"medium-gray": "#2B2C2E",
				"light-gray": "#3B3C3E",
				"extra-light-gray": "#545557",
				white: "#DEDFE1",
			},
		},
	},
	plugins: [],
};
