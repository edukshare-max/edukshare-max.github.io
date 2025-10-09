const { PromocionSalud, CategoriaPromocion, DepartamentoSalud } = require('../models/PromocionSalud');
const { sequelize } = require('../config/database');

/**
 * Script para poblar la base de datos con datos de prueba realistas
 * Sistema SASU - Universidad Autónoma de Guerrero
 */
class DataSeeder {
  
  async seedAll() {
    try {
      console.log('[DataSeeder] 🔄 Inicializando base de datos SASU...');
      console.log('[DataSeeder] 📊 Entorno:', process.env.NODE_ENV || 'development');
      console.log('[DataSeeder] ℹ️  NOTA: Este backend solo LEE promociones de la BD SASU');
      console.log('[DataSeeder] ℹ️  Las promociones se crean desde otra aplicación\n');
      
      // Sincronizar modelos (crear tablas si no existen, sin borrar datos)
      console.log('[DataSeeder] 🔄 Sincronizando modelos con base de datos existente...');
      await sequelize.sync({ force: false, alter: false });
      console.log('[DataSeeder] ✅ Modelos sincronizados con tablas existentes');
      
      // NO poblar datos - solo verificar estructura
      console.log('\n[DataSeeder] 🔍 Verificando tablas existentes...');
      
      // Mostrar resumen de datos existentes
      const countCategorias = await CategoriaPromocion.count();
      const countDepartamentos = await DepartamentoSalud.count();
      const countPromociones = await PromocionSalud.count();
      
      console.log('\n[DataSeeder] 📊 DATOS ACTUALES EN BASE DE DATOS:');
      console.log(`  • Categorías: ${countCategorias}`);
      console.log(`  • Departamentos: ${countDepartamentos}`);
      console.log(`  • Promociones: ${countPromociones}`);
      
      if (countPromociones === 0) {
        console.log('\n[DataSeeder] ⚠️  No hay promociones en la base de datos');
        console.log('[DataSeeder] ℹ️  Las promociones deben crearse desde la aplicación de administración');
      } else {
        console.log('\n[DataSeeder] ✅ Base de datos SASU lista para consultas');
      }
      
    } catch (error) {
      console.error('[DataSeeder] ❌ Error inicializando base de datos:', error);
      throw error;
    }
  }
  
  async seedCategorias() {
    console.log('[DataSeeder] Poblando categorías...');
    
    const categorias = [
      {
        nombre: 'Consulta Médica',
        descripcion: 'Servicios médicos generales y especialidades',
        color_hex: '#3B82F6',
        icono: '🏥'
      },
      {
        nombre: 'Prevención',
        descripcion: 'Programas de prevención y salud pública',
        color_hex: '#10B981',
        icono: '🛡️'
      },
      {
        nombre: 'Emergencia',
        descripcion: 'Servicios de urgencias y emergencias médicas',
        color_hex: '#EF4444',
        icono: '🚨'
      },
      {
        nombre: 'Salud Mental',
        descripcion: 'Apoyo psicológico y bienestar emocional',
        color_hex: '#8B5CF6',
        icono: '🧠'
      },
      {
        nombre: 'Nutrición',
        descripcion: 'Programas de alimentación y nutrición',
        color_hex: '#F59E0B',
        icono: '🥗'
      },
      {
        nombre: 'Deportes',
        descripcion: 'Actividades físicas y medicina deportiva',
        color_hex: '#06B6D4',
        icono: '⚽'
      },
      {
        nombre: 'Información',
        descripcion: 'Recursos informativos y educativos',
        color_hex: '#6B7280',
        icono: '📱'
      }
    ];
    
    for (const categoria of categorias) {
      await CategoriaPromocion.findOrCreate({
        where: { nombre: categoria.nombre },
        defaults: categoria
      });
    }
    
    console.log(`[DataSeeder] ✅ ${categorias.length} categorías pobladas`);
  }
  
  async seedDepartamentos() {
    console.log('[DataSeeder] Poblando departamentos...');
    
    const departamentos = [
      {
        nombre: 'Consultorio Médico General',
        descripcion: 'Atención médica primaria para estudiantes',
        contacto_email: 'medico@uagro.mx',
        contacto_telefono: '+52 744 445 1100',
        ubicacion: 'Edificio Central, Planta Baja'
      },
      {
        nombre: 'Servicios Psicológicos',
        descripcion: 'Apoyo psicológico y counseling estudiantil',
        contacto_email: 'psicologia@uagro.mx',
        contacto_telefono: '+52 744 445 1101',
        ubicacion: 'Centro de Bienestar Estudiantil'
      },
      {
        nombre: 'Departamento de Nutrición',
        descripcion: 'Programas de alimentación saludable',
        contacto_email: 'nutricion@uagro.mx',
        contacto_telefono: '+52 744 445 1102',
        ubicacion: 'Cafetería Central'
      },
      {
        nombre: 'Medicina Deportiva',
        descripcion: 'Atención médica para deportistas',
        contacto_email: 'deportes@uagro.mx',
        contacto_telefono: '+52 744 445 1103',
        ubicacion: 'Centro Deportivo UAGro'
      },
      {
        nombre: 'Servicios de Emergencia',
        descripcion: 'Atención de urgencias 24/7',
        contacto_email: 'emergencias@uagro.mx',
        contacto_telefono: '+52 744 445 1104',
        ubicacion: 'Clínica Universitaria'
      },
      {
        nombre: 'Promoción de la Salud',
        descripcion: 'Campañas educativas y preventivas',
        contacto_email: 'promocion@uagro.mx',
        contacto_telefono: '+52 744 445 1105',
        ubicacion: 'Rectoría, 2do Piso'
      }
    ];
    
    for (const departamento of departamentos) {
      await DepartamentoSalud.findOrCreate({
        where: { nombre: departamento.nombre },
        defaults: departamento
      });
    }
    
    console.log(`[DataSeeder] ✅ ${departamentos.length} departamentos poblados`);
  }
  
  async seedPromociones() {
    console.log('[DataSeeder] Poblando promociones...');
    
    // Obtener IDs de categorías y departamentos
    const categorias = await CategoriaPromocion.findAll();
    const departamentos = await DepartamentoSalud.findAll();
    
    const categoriasMap = {};
    const departamentosMap = {};
    
    categorias.forEach(cat => {
      categoriasMap[cat.nombre] = cat.id;
    });
    
    departamentos.forEach(dep => {
      departamentosMap[dep.nombre] = dep.id;
    });
    
    const hoy = new Date();
    const en7Dias = new Date(hoy.getTime() + (7 * 24 * 60 * 60 * 1000));
    const en15Dias = new Date(hoy.getTime() + (15 * 24 * 60 * 60 * 1000));
    const en30Dias = new Date(hoy.getTime() + (30 * 24 * 60 * 60 * 1000));
    const en60Dias = new Date(hoy.getTime() + (60 * 24 * 60 * 60 * 1000));
    const en90Dias = new Date(hoy.getTime() + (90 * 24 * 60 * 60 * 1000));
    
    const promociones = [
      // Promociones específicas para matrícula 15662
      {
        titulo: 'Consulta Médica Especializada - Estudiante 15662',
        descripcion: 'Estimado estudiante con matrícula 15662, tienes una consulta médica programada con el Dr. Martinez. Esta cita incluye revisión general, análisis de laboratorio pendientes y seguimiento de tu expediente médico. Es importante que asistas puntualmente y traigas tu carnet estudiantil.',
        resumen: 'Consulta médica programada con el Dr. Martinez - Trae tu carnet estudiantil',
        link: 'https://citas.uagro.mx/consulta/15662/dr-martinez',
        imagen_url: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Consulta Médica'],
        departamento_id: departamentosMap['Consultorio Médico General'],
        matricula_target: '15662',
        fecha_inicio: hoy,
        fecha_fin: en30Dias,
        destacado: true,
        urgente: false,
        prioridad: 10
      },
      {
        titulo: 'Campaña de Vacunación - Registro Confirmado',
        descripcion: 'La Universidad Autónoma de Guerrero invita a todos los estudiantes a participar en la campaña de vacunación contra la influenza estacional. El proceso es gratuito y se realizará en el consultorio médico. Estudiante 15662, tu registro está confirmado para el próximo lunes.',
        resumen: 'Campaña de vacunación gratuita - Registro confirmado',
        link: 'https://vacunacion.uagro.mx/registro/15662',
        imagen_url: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Prevención'],
        departamento_id: departamentosMap['Promoción de la Salud'],
        matricula_target: '15662',
        fecha_inicio: hoy,
        fecha_fin: en15Dias,
        destacado: true,
        urgente: false,
        prioridad: 9
      },
      {
        titulo: 'Seguimiento Nutricional Personalizado - 15662',
        descripcion: 'Tu evaluación nutricional ha sido completada. Los resultados muestran que estás en un excelente estado nutricional. Te invitamos a continuar con el seguimiento mensual para mantener tus hábitos alimentarios saludables y optimizar tu rendimiento académico.',
        resumen: 'Seguimiento nutricional personalizado disponible',
        link: 'https://nutricion.uagro.mx/seguimiento/15662',
        imagen_url: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Nutrición'],
        departamento_id: departamentosMap['Departamento de Nutrición'],
        matricula_target: '15662',
        fecha_inicio: hoy,
        fecha_fin: en60Dias,
        destacado: false,
        urgente: false,
        prioridad: 8
      },
      
      // Promociones generales (para todos los estudiantes)
      {
        titulo: 'Servicio de Nutrición - Evaluación Gratuita',
        descripcion: 'El Departamento de Nutrición ofrece evaluaciones nutricionales gratuitas para todos los estudiantes. Incluye análisis de composición corporal, plan alimentario personalizado y seguimiento mensual. Ideal para estudiantes que buscan mejorar su rendimiento académico a través de una mejor alimentación.',
        resumen: 'Evaluación nutricional gratuita con plan personalizado',
        link: 'https://nutricion.uagro.mx/evaluacion',
        imagen_url: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Nutrición'],
        departamento_id: departamentosMap['Departamento de Nutrición'],
        matricula_target: null,
        fecha_inicio: hoy,
        fecha_fin: en60Dias,
        destacado: false,
        urgente: false,
        prioridad: 7
      },
      {
        titulo: 'Apoyo Psicológico - Sesiones Individuales',
        descripcion: 'Los Servicios Psicológicos de la UAGro ofrecen sesiones individuales de apoyo emocional y counseling académico. Nuestros psicólogos certificados brindan un espacio seguro y confidencial para estudiantes que enfrentan estrés, ansiedad o dificultades de adaptación universitaria.',
        resumen: 'Sesiones de apoyo psicológico confidenciales y gratuitas',
        link: 'https://psicologia.uagro.mx/citas',
        imagen_url: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Salud Mental'],
        departamento_id: departamentosMap['Servicios Psicológicos'],
        matricula_target: null,
        fecha_inicio: hoy,
        fecha_fin: en90Dias,
        destacado: true,
        urgente: false,
        prioridad: 8
      },
      {
        titulo: 'Actualización de Expediente Médico - Acción Requerida',
        descripcion: 'Es importante mantener actualizado tu expediente médico universitario. Estudiantes que no han completado su información médica en los últimos 2 años deben agendar una cita para actualización. Esto es obligatorio para participar en actividades deportivas y viajes académicos.',
        resumen: 'Actualización obligatoria de expediente médico',
        link: 'https://expedientes.uagro.mx/actualizacion',
        imagen_url: 'https://images.unsplash.com/photo-1504813184591-01572f98c85f?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Información'],
        departamento_id: departamentosMap['Consultorio Médico General'],
        matricula_target: null,
        fecha_inicio: hoy,
        fecha_fin: en60Dias,
        destacado: false,
        urgente: false,
        prioridad: 6
      },
      {
        titulo: 'Programa de Actividad Física - Inscripciones Abiertas',
        descripcion: 'El Centro Deportivo UAGro invita a todos los estudiantes a participar en nuestros programas de actividad física. Incluye clases de yoga, pilates, crossfit, natación y deportes en equipo. Fortalece tu cuerpo mientras estudias y conoce nuevos amigos.',
        resumen: 'Programas deportivos variados - Inscripciones abiertas',
        link: 'https://deportes.uagro.mx/inscripciones',
        imagen_url: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Deportes'],
        departamento_id: departamentosMap['Medicina Deportiva'],
        matricula_target: null,
        fecha_inicio: hoy,
        fecha_fin: en90Dias,
        destacado: true,
        urgente: false,
        prioridad: 7
      },
      {
        titulo: 'Campaña de Donación de Sangre - Voluntarios Necesarios',
        descripcion: 'La UAGro en colaboración con la Cruz Roja organiza una campaña de donación de sangre. Tu donación puede salvar hasta 3 vidas. Proceso seguro, rápido y profesional. Incluye examen médico gratuito y refrigerio posterior.',
        resumen: 'Donación de sangre - Salva vidas, dona sangre',
        link: 'https://donacion.uagro.mx/voluntarios',
        imagen_url: 'https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Prevención'],
        departamento_id: departamentosMap['Promoción de la Salud'],
        matricula_target: null,
        fecha_inicio: hoy,
        fecha_fin: en30Dias,
        destacado: false,
        urgente: true,
        prioridad: 9
      },
      {
        titulo: 'Taller de Manejo del Estrés Académico',
        descripcion: 'Los períodos de exámenes pueden generar altos niveles de estrés. Aprende técnicas efectivas de relajación, organización del tiempo y manejo de la ansiedad. Taller práctico con ejercicios de respiración, mindfulness y planificación académica.',
        resumen: 'Técnicas para manejar el estrés de los exámenes',
        link: 'https://talleres.uagro.mx/estres-academico',
        imagen_url: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Salud Mental'],
        departamento_id: departamentosMap['Servicios Psicológicos'],
        matricula_target: null,
        fecha_inicio: hoy,
        fecha_fin: en15Dias,
        destacado: true,
        urgente: false,
        prioridad: 8
      },
      {
        titulo: 'Servicio de Emergencias 24/7 - Información Importante',
        descripcion: 'Recuerda que el servicio de emergencias de la UAGro está disponible 24 horas, 7 días a la semana. En caso de urgencia médica, accidente o crisis de salud mental, no dudes en contactarnos. Personal médico capacitado y ambulancia disponible.',
        resumen: 'Emergencias 24/7 - Siempre disponibles para ti',
        link: 'https://emergencias.uagro.mx/contacto',
        imagen_url: 'https://images.unsplash.com/photo-1551190822-a9333d879b1f?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Emergencia'],
        departamento_id: departamentosMap['Servicios de Emergencia'],
        matricula_target: null,
        fecha_inicio: hoy,
        fecha_fin: en90Dias,
        destacado: false,
        urgente: false,
        prioridad: 5
      },
      
      // Promociones adicionales específicas para otras matrículas (datos de prueba)
      {
        titulo: 'Cita de Seguimiento - Estudiante 12345',
        descripcion: 'Recordatorio de cita de seguimiento programada para el estudiante con matrícula 12345. Es importante asistir para evaluar tu progreso de salud.',
        resumen: 'Cita de seguimiento programada',
        link: 'https://citas.uagro.mx/seguimiento/12345',
        imagen_url: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Consulta Médica'],
        departamento_id: departamentosMap['Consultorio Médico General'],
        matricula_target: '12345',
        fecha_inicio: hoy,
        fecha_fin: en7Dias,
        destacado: true,
        urgente: false,
        prioridad: 10
      },
      {
        titulo: 'Evaluación Psicológica Programada - 67890',
        descripcion: 'Estimado estudiante 67890, tu evaluación psicológica está programada para la próxima semana. Esta evaluación es parte del programa de bienestar estudiantil.',
        resumen: 'Evaluación psicológica programada',
        link: 'https://psicologia.uagro.mx/evaluacion/67890',
        imagen_url: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=300&fit=crop',
        categoria_id: categoriasMap['Salud Mental'],
        departamento_id: departamentosMap['Servicios Psicológicos'],
        matricula_target: '67890',
        fecha_inicio: hoy,
        fecha_fin: en15Dias,
        destacado: false,
        urgente: false,
        prioridad: 7
      }
    ];
    
    for (const promocion of promociones) {
      await PromocionSalud.findOrCreate({
        where: { 
          titulo: promocion.titulo,
          matricula_target: promocion.matricula_target 
        },
        defaults: promocion
      });
    }
    
    console.log(`[DataSeeder] ✅ ${promociones.length} promociones pobladas`);
  }
  
  /**
   * Limpia todas las promociones (útil para testing)
   */
  async clearPromociones() {
    console.log('[DataSeeder] Limpiando promociones...');
    await PromocionSalud.destroy({ where: {} });
    console.log('[DataSeeder] ✅ Promociones limpiadas');
  }
  
  /**
   * Actualiza promociones existentes con nuevos datos
   */
  async updatePromociones() {
    console.log('[DataSeeder] Actualizando promociones...');
    
    // Actualizar URL de imágenes a URLs más consistentes
    const promociones = await PromocionSalud.findAll();
    
    for (const promocion of promociones) {
      if (!promocion.imagen_url || promocion.imagen_url.includes('unsplash')) {
        const nuevaImagen = this.getImagenPorCategoria(promocion.categoria_id);
        await promocion.update({ imagen_url: nuevaImagen });
      }
    }
    
    console.log('[DataSeeder] ✅ Promociones actualizadas');
  }
  
  /**
   * Obtiene URL de imagen apropiada según la categoría
   */
  getImagenPorCategoria(categoriaId) {
    const imagenes = {
      1: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=300&fit=crop', // Consulta Médica
      2: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400&h=300&fit=crop', // Prevención
      3: 'https://images.unsplash.com/photo-1551190822-a9333d879b1f?w=400&h=300&fit=crop', // Emergencia
      4: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=300&fit=crop', // Salud Mental
      5: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&h=300&fit=crop', // Nutrición
      6: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop', // Deportes
      7: 'https://images.unsplash.com/photo-1504813184591-01572f98c85f?w=400&h=300&fit=crop'  // Información
    };
    
    return imagenes[categoriaId] || imagenes[1];
  }
  
  /**
   * Genera estadísticas de los datos poblados
   */
  async generateStats() {
    const [totalCategorias, totalDepartamentos, totalPromociones, promocionesActivas, promocionesEspecificas] = await Promise.all([
      CategoriaPromocion.count(),
      DepartamentoSalud.count(),
      PromocionSalud.count(),
      PromocionSalud.count({ where: { activo: true } }),
      PromocionSalud.count({ where: { matricula_target: { [Op.ne]: null } } })
    ]);
    
    console.log('\n[DataSeeder] 📊 ESTADÍSTICAS DE DATOS POBLADOS:');
    console.log(`├── Categorías: ${totalCategorias}`);
    console.log(`├── Departamentos: ${totalDepartamentos}`);
    console.log(`├── Promociones totales: ${totalPromociones}`);
    console.log(`├── Promociones activas: ${promocionesActivas}`);
    console.log(`└── Promociones específicas: ${promocionesEspecificas}`);
    
    return {
      categorias: totalCategorias,
      departamentos: totalDepartamentos,
      promociones: totalPromociones,
      promociones_activas: promocionesActivas,
      promociones_especificas: promocionesEspecificas
    };
  }
}

// Exportar instancia y función para ejecutar desde línea de comandos
const seeder = new DataSeeder();

// Si se ejecuta directamente
if (require.main === module) {
  seeder.seedAll()
    .then(() => seeder.generateStats())
    .then(() => {
      console.log('\n[DataSeeder] 🎉 ¡Población de datos completada exitosamente!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n[DataSeeder] 💥 Error en población de datos:', error);
      process.exit(1);
    });
}

module.exports = seeder;