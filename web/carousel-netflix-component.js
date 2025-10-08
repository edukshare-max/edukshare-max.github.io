/**
 * PROMOCIONES SALUD UAGro - Componente Carrusel Netflix/Prime
 * Sistema de carrusel horizontal con auto-play y navegación
 * Compatible con autenticación JWT y targeting por departamento
 */

class PromocionesCarousel {
    constructor(containerId, options = {}) {
        this.container = document.getElementById(containerId);
        this.apiUrl = options.apiUrl || 'https://alumno-backend-node.onrender.com/api';
        
        // Configuración del carrusel
        this.config = {
            autoPlayInterval: options.autoPlayInterval || 5000,
            itemsPerView: options.itemsPerView || 3,
            slideSpeed: options.slideSpeed || 600,
            enableAutoPlay: options.enableAutoPlay !== false,
            enableTouch: options.enableTouch !== false,
            ...options
        };
        
        // Estado del carrusel
        this.state = {
            currentIndex: 0,
            promociones: [],
            isLoading: false,
            autoPlayTimer: null,
            isAutoPlaying: false
        };
        
        // Elementos DOM
        this.elements = {};
        
        this.init();
    }

    async init() {
        try {
            this.render();
            await this.loadPromociones();
            this.setupEventListeners();
            this.startAutoPlay();
        } catch (error) {
            console.error('Error al inicializar carrusel:', error);
            this.showError('Error al cargar promociones');
        }
    }

    render() {
        this.container.innerHTML = `
            <div class="promociones-carousel-section">
                <div class="promociones-carousel-header">
                    <div>
                        <h3 class="promociones-carousel-title">
                            🏥 Promoción a la Salud
                        </h3>
                        <p class="promociones-carousel-subtitle">
                            Información importante para tu bienestar
                        </p>
                    </div>
                    <div class="carousel-controls">
                        <button class="carousel-nav-btn" id="carousel-prev" title="Anterior">
                            ‹
                        </button>
                        <button class="carousel-nav-btn" id="carousel-next" title="Siguiente">
                            ›
                        </button>
                        <button class="carousel-auto-toggle" id="carousel-auto" title="Auto-reproducir">
                            ⏸️ Auto
                        </button>
                    </div>
                </div>

                <div class="promociones-carousel-container" id="carousel-container">
                    <div class="carousel-loading" id="carousel-loading">
                        <div class="carousel-spinner"></div>
                        Cargando promociones...
                    </div>
                </div>

                <div class="carousel-progress" id="carousel-progress">
                    <!-- Indicadores dinámicos -->
                </div>
            </div>
        `;

        // Obtener referencias a elementos
        this.elements = {
            container: document.getElementById('carousel-container'),
            loading: document.getElementById('carousel-loading'),
            progress: document.getElementById('carousel-progress'),
            prevBtn: document.getElementById('carousel-prev'),
            nextBtn: document.getElementById('carousel-next'),
            autoBtn: document.getElementById('carousel-auto')
        };
    }

    async loadPromociones() {
        this.state.isLoading = true;
        this.showLoading();

        try {
            const token = localStorage.getItem('authToken');
            if (!token) {
                this.showEmpty('Inicia sesión para ver promociones');
                return;
            }

            const response = await fetch(`${this.apiUrl}/me/promociones`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`Error ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            this.state.promociones = data.promociones || [];
            
            if (this.state.promociones.length === 0) {
                this.showEmpty('No hay promociones disponibles');
            } else {
                this.renderCarousel();
                this.updateProgress();
                this.updateNavigation();
            }
        } catch (error) {
            console.error('Error cargando promociones:', error);
            this.showError('Error al cargar promociones');
        } finally {
            this.state.isLoading = false;
        }
    }

    renderCarousel() {
        const track = this.createCarouselTrack();
        this.elements.container.innerHTML = '';
        this.elements.container.appendChild(track);
    }

    createCarouselTrack() {
        const track = document.createElement('div');
        track.className = 'promociones-carousel-track';
        track.id = 'carousel-track';

        this.state.promociones.forEach((promocion, index) => {
            const card = this.createCarouselCard(promocion, index);
            track.appendChild(card);
        });

        return track;
    }

    createCarouselCard(promocion, index) {
        const card = document.createElement('div');
        card.className = `promocion-carousel-card ${promocion.departamento?.toLowerCase() || 'general'}`;
        card.setAttribute('data-index', index);

        // Formatear fecha
        const fecha = new Date(promocion.fechaCreacion);
        const fechaFormateada = fecha.toLocaleDateString('es-MX', {
            day: 'numeric',
            month: 'short'
        });

        // Determinar icono de targeting
        const targetIcon = this.getTargetIcon(promocion.grupoObjetivo);
        const targetText = this.getTargetText(promocion.grupoObjetivo, promocion.matriculaEspecifica);

        card.innerHTML = `
            <div class="carousel-card-content">
                <div class="carousel-card-header">
                    <span class="carousel-dept-badge ${promocion.departamento?.toLowerCase() || 'general'}">
                        ${this.getDepartmentIcon(promocion.departamento)} ${promocion.departamento || 'General'}
                    </span>
                    <span class="carousel-priority ${promocion.prioridad?.toLowerCase() || 'media'}">
                        ${promocion.prioridad || 'Media'}
                    </span>
                </div>

                <div class="carousel-card-description">
                    ${promocion.descripcion || 'Sin descripción disponible'}
                </div>

                <div class="carousel-card-target">
                    ${targetIcon} ${targetText}
                </div>

                <div class="carousel-card-actions">
                    <button class="carousel-btn-primary" onclick="promocionesCarousel.abrirPromocion('${promocion.id}')">
                        📖 Ver detalles
                    </button>
                    <button class="carousel-btn-share" onclick="promocionesCarousel.compartirPromocion('${promocion.id}')" title="Compartir">
                        📤
                    </button>
                </div>
            </div>
        `;

        // Evento click para navegación
        card.addEventListener('click', (e) => {
            if (!e.target.closest('button')) {
                this.pauseAutoPlay();
                this.goToSlide(index);
            }
        });

        return card;
    }

    setupEventListeners() {
        // Navegación
        this.elements.prevBtn?.addEventListener('click', () => this.previousSlide());
        this.elements.nextBtn?.addEventListener('click', () => this.nextSlide());
        
        // Auto-play toggle
        this.elements.autoBtn?.addEventListener('click', () => this.toggleAutoPlay());

        // Touch/swipe support
        if (this.config.enableTouch) {
            this.setupTouchListeners();
        }

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (this.container.contains(document.activeElement)) {
                if (e.key === 'ArrowLeft') this.previousSlide();
                if (e.key === 'ArrowRight') this.nextSlide();
                if (e.key === ' ') {
                    e.preventDefault();
                    this.toggleAutoPlay();
                }
            }
        });

        // Pause on hover
        this.container.addEventListener('mouseenter', () => this.pauseAutoPlay());
        this.container.addEventListener('mouseleave', () => {
            if (this.state.isAutoPlaying) this.startAutoPlay();
        });
    }

    setupTouchListeners() {
        let startX = 0;
        let moveX = 0;
        let isDragging = false;

        const track = () => this.container.querySelector('#carousel-track');

        this.container.addEventListener('touchstart', (e) => {
            startX = e.touches[0].clientX;
            isDragging = true;
            this.pauseAutoPlay();
        });

        this.container.addEventListener('touchmove', (e) => {
            if (!isDragging) return;
            moveX = e.touches[0].clientX - startX;
            e.preventDefault();
        });

        this.container.addEventListener('touchend', () => {
            if (!isDragging) return;
            isDragging = false;

            const threshold = 50; // Umbral mínimo para el swipe
            if (Math.abs(moveX) > threshold) {
                if (moveX > 0) {
                    this.previousSlide();
                } else {
                    this.nextSlide();
                }
            }
            moveX = 0;
        });
    }

    // Navegación del carrusel
    nextSlide() {
        const maxIndex = Math.max(0, this.state.promociones.length - this.config.itemsPerView);
        this.state.currentIndex = Math.min(this.state.currentIndex + 1, maxIndex);
        this.updateCarousel();
    }

    previousSlide() {
        this.state.currentIndex = Math.max(this.state.currentIndex - 1, 0);
        this.updateCarousel();
    }

    goToSlide(index) {
        const maxIndex = Math.max(0, this.state.promociones.length - this.config.itemsPerView);
        this.state.currentIndex = Math.max(0, Math.min(index, maxIndex));
        this.updateCarousel();
    }

    updateCarousel() {
        const track = this.container.querySelector('#carousel-track');
        if (!track) return;

        const cardWidth = 320 + 16; // ancho + gap
        const translateX = -this.state.currentIndex * cardWidth;
        
        track.style.transform = `translateX(${translateX}px)`;
        
        this.updateProgress();
        this.updateNavigation();
    }

    updateNavigation() {
        const maxIndex = Math.max(0, this.state.promociones.length - this.config.itemsPerView);
        
        if (this.elements.prevBtn) {
            this.elements.prevBtn.disabled = this.state.currentIndex === 0;
        }
        
        if (this.elements.nextBtn) {
            this.elements.nextBtn.disabled = this.state.currentIndex >= maxIndex;
        }
    }

    updateProgress() {
        if (!this.elements.progress || this.state.promociones.length === 0) return;

        const totalSlides = Math.max(1, this.state.promociones.length - this.config.itemsPerView + 1);
        const dots = Array.from({ length: totalSlides }, (_, index) => {
            const dot = document.createElement('div');
            dot.className = `carousel-dot ${index === this.state.currentIndex ? 'active' : ''}`;
            dot.addEventListener('click', () => this.goToSlide(index));
            return dot;
        });

        this.elements.progress.innerHTML = '';
        dots.forEach(dot => this.elements.progress.appendChild(dot));
    }

    // Auto-play
    startAutoPlay() {
        if (!this.config.enableAutoPlay || this.state.promociones.length <= this.config.itemsPerView) return;
        
        this.stopAutoPlay();
        this.state.isAutoPlaying = true;
        
        this.state.autoPlayTimer = setInterval(() => {
            const maxIndex = Math.max(0, this.state.promociones.length - this.config.itemsPerView);
            
            if (this.state.currentIndex >= maxIndex) {
                this.goToSlide(0); // Volver al inicio
            } else {
                this.nextSlide();
            }
        }, this.config.autoPlayInterval);

        this.updateAutoPlayButton();
    }

    stopAutoPlay() {
        if (this.state.autoPlayTimer) {
            clearInterval(this.state.autoPlayTimer);
            this.state.autoPlayTimer = null;
        }
    }

    pauseAutoPlay() {
        this.stopAutoPlay();
        this.state.isAutoPlaying = false;
        this.updateAutoPlayButton();
    }

    toggleAutoPlay() {
        if (this.state.isAutoPlaying) {
            this.pauseAutoPlay();
        } else {
            this.startAutoPlay();
        }
    }

    updateAutoPlayButton() {
        if (!this.elements.autoBtn) return;
        
        const isPlaying = this.state.isAutoPlaying && this.state.autoPlayTimer;
        this.elements.autoBtn.innerHTML = isPlaying ? '⏸️ Auto' : '▶️ Auto';
        this.elements.autoBtn.className = `carousel-auto-toggle ${isPlaying ? 'active' : ''}`;
    }

    // Acciones de promociones
    async abrirPromocion(promocionId) {
        const promocion = this.state.promociones.find(p => p.id === promocionId);
        if (!promocion) return;

        // Crear modal o ventana con detalles completos
        const modal = this.createPromocionModal(promocion);
        document.body.appendChild(modal);
        
        // Mostrar modal
        setTimeout(() => modal.classList.add('show'), 10);
    }

    async compartirPromocion(promocionId) {
        const promocion = this.state.promociones.find(p => p.id === promocionId);
        if (!promocion) return;

        const shareData = {
            title: `Promoción de Salud - ${promocion.departamento}`,
            text: promocion.descripcion,
            url: window.location.href
        };

        try {
            if (navigator.share && navigator.canShare(shareData)) {
                await navigator.share(shareData);
            } else {
                // Fallback: copiar al portapapeles
                await navigator.clipboard.writeText(
                    `🏥 ${shareData.title}\n\n${shareData.text}\n\n${shareData.url}`
                );
                this.showToast('Enlace copiado al portapapeles');
            }
        } catch (error) {
            console.error('Error al compartir:', error);
        }
    }

    createPromocionModal(promocion) {
        const modal = document.createElement('div');
        modal.className = 'promocion-modal-overlay';
        modal.innerHTML = `
            <div class="promocion-modal">
                <div class="promocion-modal-header">
                    <h3>${promocion.departamento || 'Promoción'} - ${promocion.prioridad}</h3>
                    <button class="promocion-modal-close">&times;</button>
                </div>
                <div class="promocion-modal-body">
                    <p><strong>Descripción:</strong></p>
                    <p>${promocion.descripcion}</p>
                    
                    <p><strong>Dirigido a:</strong></p>
                    <p>${this.getTargetText(promocion.grupoObjetivo, promocion.matriculaEspecifica)}</p>
                    
                    <p><strong>Fecha:</strong></p>
                    <p>${new Date(promocion.fechaCreacion).toLocaleString('es-MX')}</p>
                </div>
                <div class="promocion-modal-actions">
                    <button class="carousel-btn-primary" onclick="this.closest('.promocion-modal-overlay').remove()">
                        Cerrar
                    </button>
                </div>
            </div>
        `;

        // Cerrar modal
        modal.addEventListener('click', (e) => {
            if (e.target === modal || e.target.classList.contains('promocion-modal-close')) {
                modal.remove();
            }
        });

        return modal;
    }

    // Utilidades
    showLoading() {
        if (this.elements.loading) {
            this.elements.loading.style.display = 'flex';
        }
    }

    showEmpty(message) {
        this.elements.container.innerHTML = `
            <div class="carousel-empty">
                <div class="carousel-empty-icon">🏥</div>
                <div class="carousel-empty-text">${message}</div>
            </div>
        `;
    }

    showError(message) {
        this.elements.container.innerHTML = `
            <div class="carousel-empty">
                <div class="carousel-empty-icon">❌</div>
                <div class="carousel-empty-text">${message}</div>
                <button class="carousel-btn-primary" onclick="promocionesCarousel.loadPromociones()" style="margin-top: 12px;">
                    Reintentar
                </button>
            </div>
        `;
    }

    showToast(message) {
        const toast = document.createElement('div');
        toast.className = 'carousel-toast';
        toast.textContent = message;
        document.body.appendChild(toast);
        
        setTimeout(() => toast.classList.add('show'), 10);
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    }

    getDepartmentIcon(departamento) {
        const icons = {
            'medicina': '🩺',
            'enfermeria': '💉',
            'odontologia': '🦷',
            'psicologia': '🧠',
            'veterinaria': '🐕',
            'general': '🏥'
        };
        return icons[departamento?.toLowerCase()] || icons.general;
    }

    getTargetIcon(grupoObjetivo) {
        const icons = {
            'todos': '👥',
            'estudiante_especifico': '👤',
            'por_departamento': '🏢'
        };
        return icons[grupoObjetivo] || icons.todos;
    }

    getTargetText(grupoObjetivo, matriculaEspecifica) {
        switch (grupoObjetivo) {
            case 'todos':
                return 'Todos los estudiantes';
            case 'estudiante_especifico':
                return `Estudiante: ${matriculaEspecifica || 'No especificado'}`;
            case 'por_departamento':
                return 'Estudiantes del departamento';
            default:
                return 'Targeting no especificado';
        }
    }

    // Métodos públicos
    refresh() {
        this.loadPromociones();
    }

    destroy() {
        this.stopAutoPlay();
        this.container.innerHTML = '';
    }

    updateConfig(newConfig) {
        this.config = { ...this.config, ...newConfig };
    }
}

// Instancia global para facilitar el uso
let promocionesCarousel;