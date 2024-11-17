<script lang="ts">
	// Components
	import Smoothness from "$lib/components/Smoothness.svelte";
	import Shapes from "$lib/components/Shapes.svelte";
	import Speed from "$lib/components/Speed.svelte";
	import Operation from "$lib/components/Operation.svelte";
</script>

<!-- Main container -->
<div
	class="bg-medium-gray rounded-2xl w-full justify-between border border-light-gray sm:w-96 h-full p-4 text-sm text-white flex flex-col"
>
	<div class="flex flex-col gap-4">
		<Speed />
		<Smoothness />
		<Shapes />
		<Operation />
	</div>
	<span class="text-gray-400 text-xs w-full justify-center items-center flex flex-row gap-1">
		Made by
		<a href="https://www.hugoduprez.com/" target="_blank" class="underline"> Hugo </a>
	</span>
</div>
