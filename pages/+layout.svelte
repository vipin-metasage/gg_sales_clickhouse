<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';
	export let data;
</script>

<div class="flex flex-col min-h-screen w-full">
    <!-- Main Content Area with Sidebar and Breadcrumbs Hidden -->
    <EvidenceDefaultLayout {data}  hideBreadcrumbs = true sidebar=never hide_title=true hideSidebar = true logo = /globalgreen.png neverShowQueries = true hideTOC = true >
        <slot slot="content" />
    </EvidenceDefaultLayout>

    <!-- Footer Navigation Bar -->
    <footer class="bg-gray-800 text-white py-3 px-5 shadow-md fixed bottom-0 left-0 w-full rounded-t-sm">
        <ul class="flex justify-center gap-6 text-sm">
            <li><a href="/" class="hover:text-green-400">📈 Overview</a></li>
            <li><a href="/invoice" class="hover:text-green-400">🏠 Invoice Insights</a></li>
            

        </ul>
    </footer>
    
</div>