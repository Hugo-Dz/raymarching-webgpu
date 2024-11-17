<script lang="ts">
	import "../app.css";
</script>

<slot />

<style>
	/* Thumb styles for WebKit browsers (Chrome, Safari, newer versions of Opera) */
	:global(.styled-range::-webkit-slider-thumb) {
		-webkit-appearance: none;
		appearance: none;
		width: 8px;
		height: 20px;
		background: #dedfe1;
		border-radius: 2px;
		cursor: pointer;
	}

	:global(.styled-range::-moz-range-thumb) {
		width: 8px;
		height: 20px;
		background: #dedfe1;
		border-radius: 2px;
		cursor: pointer;
		border: none;
	}
</style>
