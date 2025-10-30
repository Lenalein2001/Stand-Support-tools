document.addEventListener('DOMContentLoaded', function() {
    const container = document.getElementById('json-content');
    const loadJsonButton = document.getElementById('load-json');
    const jsonUrlInput = document.getElementById('json-url');
    const jsonFileInput = document.getElementById('json-file');

    const errorBannerCompatibility = document.getElementById('error-banner-compatibility');
    const errorBannerUpdate = document.getElementById('error-banner-update');
    const errorBannerSha = document.getElementById('error-banner-sha');
    const errorBannerConnect = document.getElementById('error-banner-connect');
    const errorBannerNetwork = document.getElementById('error-banner-network');

    let dataArray = [];

    function createSection(title, content) {
        // Handle null or undefined content
        if (content === null || content === undefined) {
            const section = document.createElement('div');
            section.classList.add('collapsible-section');
            
            const innerDiv = document.createElement('div');
            innerDiv.classList.add('collapsible-inner');
            innerDiv.style.padding = '1rem';
            
            const titleElement = document.createElement('strong');
            titleElement.textContent = title + ': ';
            titleElement.style.color = '#8fa3b8';
            innerDiv.appendChild(titleElement);
            
            const valueSpan = document.createElement('span');
            valueSpan.textContent = 'null';
            valueSpan.style.color = '#999';
            innerDiv.appendChild(valueSpan);
            
            section.appendChild(innerDiv);
            return section;
        }
        
        // Check if this is a leaf node (simple value, not an object or array with nested content)
        const isLeaf = (typeof content !== 'object');

        // Check if this is a simple object with only primitive values (no nested objects/arrays)
        const isSimpleObject = typeof content === 'object' && !Array.isArray(content) && 
                               Object.values(content).every(val => val === null || val === undefined || typeof val !== 'object');

        if (isLeaf) {
            // Create a simple non-collapsible section for leaf nodes
            const section = document.createElement('div');
            section.classList.add('collapsible-section');
            
            const innerDiv = document.createElement('div');
            innerDiv.classList.add('collapsible-inner');
            innerDiv.style.padding = '1rem';
            
            const titleElement = document.createElement('strong');
            titleElement.textContent = title + ': ';
            titleElement.style.color = '#8fa3b8';
            innerDiv.appendChild(titleElement);
            
            const valueSpan = document.createElement('span');
            valueSpan.textContent = Array.isArray(content) ? content.join(', ') : String(content);
            valueSpan.style.color = '#c5d1de';
            innerDiv.appendChild(valueSpan);
            
            section.appendChild(innerDiv);
            return section;
        }

        if (isSimpleObject) {
            // Create a simple non-collapsible section for objects with only primitive values
            const section = document.createElement('div');
            section.classList.add('collapsible-section');
            
            const innerDiv = document.createElement('div');
            innerDiv.classList.add('collapsible-inner');
            innerDiv.style.padding = '1rem';
            
            if (title) {
                const titleElement = document.createElement('div');
                titleElement.innerHTML = '<strong style="color: #8fa3b8;">' + title + '</strong>';
                titleElement.style.marginBottom = '0.5rem';
                innerDiv.appendChild(titleElement);
            }
            
            for (const key in content) {
                if (content.hasOwnProperty(key)) {
                    const line = document.createElement('div');
                    line.style.paddingLeft = '1rem';
                    line.innerHTML = '<span style="color: #8fa3b8;">' + key + ':</span> <span style="color: #c5d1de;">' + String(content[key]) + '</span>';
                    innerDiv.appendChild(line);
                }
            }
            
            section.appendChild(innerDiv);
            return section;
        }

        // Check if this is an array of simple values (strings, numbers, etc.)
        const isSimpleArray = Array.isArray(content) && content.every(item => typeof item !== 'object' || item === null);
        
        if (isSimpleArray) {
            // Create a simple non-collapsible section for arrays with simple values
            const section = document.createElement('div');
            section.classList.add('collapsible-section');
            
            const innerDiv = document.createElement('div');
            innerDiv.classList.add('collapsible-inner');
            innerDiv.style.padding = '1rem';
            
            if (title) {
                const titleElement = document.createElement('div');
                titleElement.innerHTML = '<strong style="color: #8fa3b8;">' + title + '</strong>';
                titleElement.style.marginBottom = '0.5rem';
                innerDiv.appendChild(titleElement);
            }
            
            content.forEach(item => {
                const line = document.createElement('div');
                line.style.paddingLeft = '1rem';
                line.style.color = '#c5d1de';
                line.textContent = '• ' + String(item);
                innerDiv.appendChild(line);
            });
            
            section.appendChild(innerDiv);
            return section;
        }

        // Create collapsible section for nested content
        const section = document.createElement('div');
        section.classList.add('collapsible-section');

        // Create header
        const header = document.createElement('div');
        header.classList.add('collapsible-header');
        
        const titleElement = document.createElement('h5');
        titleElement.textContent = title;
        
        const icon = document.createElement('span');
        icon.classList.add('collapsible-icon');
        icon.textContent = '▶';
        
        header.appendChild(titleElement);
        header.appendChild(icon);
        
        // Create content container
        const contentDiv = document.createElement('div');
        contentDiv.classList.add('collapsible-content');
        
        const innerDiv = document.createElement('div');
        innerDiv.classList.add('collapsible-inner');

        if (Array.isArray(content)) {
            const list = document.createElement('ul');
            content.forEach(item => {
                const listItem = document.createElement('li');
                if (typeof item === 'object' && !Array.isArray(item)) {
                    listItem.appendChild(createSection('', item));
                } else {
                    listItem.textContent = item;
                }
                list.appendChild(listItem);
            });
            innerDiv.appendChild(list);
        } else if (typeof content === 'object') {
            for (const key in content) {
                if (content.hasOwnProperty(key)) {
                    innerDiv.appendChild(createSection(key, content[key]));
                }
            }
        }

        contentDiv.appendChild(innerDiv);
        
        // Add click handler to toggle
        header.addEventListener('click', function() {
            const isExpanded = contentDiv.classList.contains('expanded');
            if (isExpanded) {
                contentDiv.classList.remove('expanded');
                icon.classList.remove('expanded');
            } else {
                contentDiv.classList.add('expanded');
                icon.classList.add('expanded');
            }
        });
        
        section.appendChild(header);
        section.appendChild(contentDiv);

        return section;
    }

    function parseProfile(profileArray) {
        const profileSection = document.createElement('div');
        profileSection.classList.add('collapsible-section');

        // Create header
        const header = document.createElement('div');
        header.classList.add('collapsible-header');
        
        const titleElement = document.createElement('h5');
        titleElement.textContent = 'Profile';
        
        const icon = document.createElement('span');
        icon.classList.add('collapsible-icon');
        icon.textContent = '▶';
        
        header.appendChild(titleElement);
        header.appendChild(icon);
        
        // Create content container
        const contentDiv = document.createElement('div');
        contentDiv.classList.add('collapsible-content');
        
        const innerDiv = document.createElement('div');
        innerDiv.classList.add('collapsible-inner');

        let currentParent = innerDiv;
        let previousIndentation = 0;
        const parentStack = [innerDiv];

        profileArray.forEach(line => {
            const currentIndentation = line.search(/\S/);
            const content = line.trim();

            const listItem = document.createElement('div');
            listItem.textContent = content;

            if (currentIndentation > previousIndentation) {
                const nestedSection = document.createElement('div');
                nestedSection.classList.add('pl-4');
                currentParent.appendChild(nestedSection);
                parentStack.push(currentParent);
                currentParent = nestedSection;
            } else if (currentIndentation < previousIndentation) {
                let diff = previousIndentation - currentIndentation;
                while (diff >= 0 && parentStack.length > 0) {
                    currentParent = parentStack.pop();
                    diff -= 1;
                }
            }

            if (currentParent) {
                currentParent.appendChild(listItem);
            }
            previousIndentation = currentIndentation;
        });

        const downloadButton = document.createElement('button');
        downloadButton.id = 'download-profile';
        downloadButton.classList.add('btn', 'btn-secondary', 'mt-3');
        downloadButton.textContent = 'Download Profile';
        innerDiv.appendChild(downloadButton);

        contentDiv.appendChild(innerDiv);
        
        // Add click handler to toggle
        header.addEventListener('click', function() {
            const isExpanded = contentDiv.classList.contains('expanded');
            if (isExpanded) {
                contentDiv.classList.remove('expanded');
                icon.classList.remove('expanded');
            } else {
                contentDiv.classList.add('expanded');
                icon.classList.add('expanded');
            }
        });
        
        profileSection.appendChild(header);
        profileSection.appendChild(contentDiv);

        return profileSection;
    }

    function createHTMLForJSON(obj, parentElement) {
        for (const key in obj) {
            if (obj.hasOwnProperty(key)) {
                let value = obj[key];
                
                // Skip null or undefined values
                if (value === null || value === undefined) {
                    continue;
                }
                
                let section;
                if (key === 'profile' && Array.isArray(value)) {
                    section = parseProfile(value);
                } else {
                    section = createSection(key, value);
                }

                parentElement.appendChild(section);
            }
        }
    }

    function showErrorBanner(bannerElement) {
        bannerElement.style.display = 'block';
        
        // Add click handler for collapsible functionality
        const header = bannerElement.querySelector('.error-banner-header');
        const content = bannerElement.querySelector('.error-banner-content');
        const icon = bannerElement.querySelector('.error-banner-icon');
        
        if (header && content && icon) {
            // Remove any existing listeners
            const newHeader = header.cloneNode(true);
            header.parentNode.replaceChild(newHeader, header);
            
            newHeader.addEventListener('click', function() {
                const isExpanded = content.classList.contains('expanded');
                if (isExpanded) {
                    content.classList.remove('expanded');
                    icon.classList.remove('expanded');
                } else {
                    content.classList.add('expanded');
                    icon.classList.add('expanded');
                }
            });
        }
    }

    function hideAllErrorBanners() {
        errorBannerCompatibility.style.display = 'none';
        errorBannerUpdate.style.display = 'none';
        errorBannerSha.style.display = 'none';
        errorBannerConnect.style.display = 'none';
        errorBannerNetwork.style.display = 'none';
    }

    function checkForErrors(jsonData) {
      hideAllErrorBanners();

      try {
          if (jsonData["EnvironmentData"] && jsonData["EnvironmentData"].isRunningInCompatibilityMode) {
              showErrorBanner(errorBannerCompatibility);
          }
          if (jsonData["Checks"] && !jsonData["Checks"].isUpToDate) {
              showErrorBanner(errorBannerUpdate);
          }
          if (jsonData["Checks"] && !jsonData["Checks"].SHAValidationCheck) {
              showErrorBanner(errorBannerSha);
          }
          if (jsonData["Checks"] && !jsonData["Checks"].IsAbleToConnect) {
              showErrorBanner(errorBannerConnect);
          }
          if (jsonData["LastInjection"] && jsonData["LastInjection"].HasNetworkIssues) {
              showErrorBanner(errorBannerNetwork);
          }
      } catch (error) {
          console.error('Error checking for errors:', error);
      }
    }

    function formatProfile(profile) {
        if (Array.isArray(profile)) {
            return profile.map(line => line.replace(/\\t/g, '\t')).join('\n');
        }
        return '';
    }

    function downloadProfileData(profileData) {
        const profileContent = profileData.profile ? formatProfile(profileData.profile) : '';
        const blob = new Blob([profileContent], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = profileData["metaState"]["profileName"] + ".txt";
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    // Helper: fetch with timeout using AbortController
    async function fetchWithTimeout(resource, options = {}) {
        const { timeout = 8000 } = options; // default 8s per proxy
        const controller = new AbortController();
        const id = setTimeout(() => controller.abort(), timeout);
        try {
            const response = await fetch(resource, { ...options, signal: controller.signal });
            return response;
        } finally {
            clearTimeout(id);
        }
    }

    // Build proxy list and request functions (return parsed JSON)
    function buildProxyRequests(url) {
        const targets = [
            { name: 'AllOrigins', url: `https://api.allorigins.win/raw?url=${encodeURIComponent(url)}` },
            { name: 'CorsProxy.io', url: `https://corsproxy.io/?${encodeURIComponent(url)}` },
            { name: 'Jina AI Mirror', url: `https://r.jina.ai/${url.startsWith('http') ? url : `http://${url}`}` },
            { name: 'CodeTabs', url: `https://api.codetabs.com/v1/proxy?quest=${encodeURIComponent(url)}` }
        ];

        return targets.map(t => async () => {
            console.log(`Trying CORS proxy: ${t.name} - ${t.url}`);
            const res = await fetchWithTimeout(t.url, { headers: { 'Accept': 'application/json, text/plain; */*' }, timeout: 9000 });
            if (!res.ok) throw new Error(`${t.name} HTTP ${res.status}`);
            // Some proxies return text/plain; parse manually
            let bodyText = await res.text();
            try {
                return JSON.parse(bodyText);
            } catch (e) {
                // Some proxies wrap results; try to extract JSON if possible
                throw new Error(`${t.name} returned non-JSON or malformed content`);
            }
        });
    }

    // Run requests in parallel and return first success
    async function fetchViaAnyProxy(url) {
        const requests = buildProxyRequests(url);
        const errors = [];
        const wrapped = requests.map(fn => fn().catch(err => { errors.push(err); throw err; }));
        try {
            return await Promise.any(wrapped);
        } catch (aggregate) {
            // All failed
            const last = errors[errors.length - 1];
            const details = errors.map(e => e.message).join(' | ');
            throw new Error(`All CORS proxies failed (${errors.length}). Last: ${last?.message}. Details: ${details}`);
        }
    }

    async function loadJSONFromUrl(url) {
        try {
            // Hide all error banners immediately when starting to load
            hideAllErrorBanners();

            let jsonData;

            if (url.startsWith('http://') || url.startsWith('https://')) {
                container.innerHTML = '<p class="text-info">Loading via multiple proxies…</p>';
                jsonData = await fetchViaAnyProxy(url);
            } else {
                // Local/relative fetch
                container.innerHTML = '<p class="text-info">Loading JSON…</p>';
                const response = await fetchWithTimeout(url, { headers: { 'Accept': 'application/json' }, timeout: 8000 });
                if (!response.ok) throw new Error('HTTP ' + response.status + ': ' + response.statusText);
                jsonData = await response.json();
            }

            dataArray.push(jsonData);

            container.innerHTML = '';
            createHTMLForJSON(jsonData, container);
            checkForErrors(jsonData);

            const downloadButton = document.getElementById('download-profile');
            if (downloadButton) {
                downloadButton.onclick = function() { downloadProfileData(jsonData); };
            }
        } catch (error) {
            console.error('Error loading JSON:', error);
            hideAllErrorBanners();
            container.innerHTML = '<p class="text-danger">Failed to load JSON: ' + error.message + '</p>';
        }
    }

    loadJsonButton.addEventListener('click', function() {
        const url = jsonUrlInput.value.trim();
        if (url) {
            loadJSONFromUrl(url);
        } else {
            hideAllErrorBanners();
            container.innerHTML = '<p class="text-danger">Please enter a URL.</p>';
        }
    });

    // Allow pressing Enter to load JSON
    jsonUrlInput.addEventListener('keypress', function(event) {
        if (event.key === 'Enter') {
            loadJsonButton.click();
        }
    });

    // Handle file upload
    jsonFileInput.addEventListener('change', function(event) {
        const file = event.target.files[0];
        if (file && file.type === 'application/json') {
            const reader = new FileReader();
            reader.onload = function(e) {
                try {
                    // Hide all error banners when starting to load new file
                    hideAllErrorBanners();

                    const jsonData = JSON.parse(e.target.result);
                    dataArray.push(jsonData);

                    container.innerHTML = '';
                    createHTMLForJSON(jsonData, container);
                    checkForErrors(jsonData);

                    const downloadButton = document.getElementById('download-profile');
                    if (downloadButton) {
                        downloadButton.onclick = function() {
                            downloadProfileData(jsonData);
                        };
                    }
                } catch (error) {
                    console.error('Error parsing JSON:', error);
                    container.innerHTML = '<p class="text-danger">Failed to parse JSON file: ' + error.message + '</p>';
                }
            };
            reader.readAsText(file);
        } else {
            hideAllErrorBanners();
            container.innerHTML = '<p class="text-danger">Please select a valid JSON file.</p>';
        }
    });

    // Drag-and-drop support

    function processJsonAfterLoad(jsonData) {
        dataArray.push(jsonData);
        container.innerHTML = '';
        createHTMLForJSON(jsonData, container);
        checkForErrors(jsonData);
        const downloadButton = document.getElementById('download-profile');
        if (downloadButton) {
            downloadButton.onclick = function() { downloadProfileData(jsonData); };
        }
    }

    function tryHandleFile(file) {
        if (!file) return false;
        if (!(/\.json$/i.test(file.name) || file.type === 'application/json')) {
            container.innerHTML = '<p class="text-danger">Drop a .json file to load it.</p>';
            return true;
        }
        const reader = new FileReader();
        reader.onload = function(ev) {
            try {
                hideAllErrorBanners();
                const jsonData = JSON.parse(ev.target.result);
                processJsonAfterLoad(jsonData);
            } catch (err) {
                container.innerHTML = '<p class="text-danger">Failed to parse dropped file: ' + err.message + '</p>';
            }
        };
        reader.readAsText(file);
        return true;
    }

    function isFileDrag(e) {
        try {
            const dt = e.dataTransfer;
            if (!dt) return false;
            // Most reliable: check DataTransferItem kinds
            if (dt.items && dt.items.length) {
                for (const it of Array.from(dt.items)) {
                    if (it.kind === 'file') return true;
                }
            }
            // Some environments only populate files during dragover
            if (dt.files && dt.files.length) return true;
            const types = dt.types ? Array.from(dt.types) : [];
            if (types.includes('Files')) return true;
            // Heuristic: some Windows shells provide no types on dragenter; assume file
            if ((e.type === 'dragenter' || e.type === 'dragover') && types.length === 0) return true;
            return false;
        } catch { return true; }
    }

    function onDragEnter(e) {
        if (!isFileDrag(e)) return; // ignore text/image drags
        e.preventDefault();
        e.stopPropagation();
        if (e.dataTransfer) e.dataTransfer.dropEffect = 'copy';
    }

    function onDragOver(e) {
        if (!isFileDrag(e)) return;
        e.preventDefault();
        e.stopPropagation();
        if (e.dataTransfer) e.dataTransfer.dropEffect = 'copy';
    }

    // Attach to both window and document with capture phase to catch all drag events
    window.addEventListener('dragenter', onDragEnter, true);
    window.addEventListener('dragover', onDragOver, true);
    window.addEventListener('drop', e => {
        e.preventDefault();
        e.stopPropagation();
        const files = e.dataTransfer && e.dataTransfer.files;
        const file = files && files[0];
        tryHandleFile(file);
    }, true);

    document.addEventListener('dragenter', onDragEnter, true);
    document.addEventListener('dragover', onDragOver, true);
  });
