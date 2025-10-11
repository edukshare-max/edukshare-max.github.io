import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/models/vacuna_model.dart';

class VacunasScreen extends StatefulWidget {
  const VacunasScreen({Key? key}) : super(key: key);

  @override
  State<VacunasScreen> createState() => _VacunasScreenState();
}

class _VacunasScreenState extends State<VacunasScreen> {
  String _filtroTipo = 'Todas';
  
  @override
  void initState() {
    super.initState();
    // Cargar vacunas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).loadVacunas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💉 Tarjeta de Vacunación'),
        backgroundColor: const Color(0xFF2E7D32), // Verde SASU
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<SessionProvider>(context, listen: false).loadVacunas();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando historial de vacunación...'),
                ],
              ),
            );
          }

          final vacunas = session.vacunas;

          if (vacunas.isEmpty) {
            return _buildEmptyState();
          }

          // Filtrar vacunas por tipo
          final vacunasFiltradas = _filtroTipo == 'Todas'
              ? vacunas
              : vacunas.where((v) => v.vacuna.contains(_filtroTipo)).toList();

          return Column(
            children: [
              _buildFiltros(vacunas),
              _buildEstadisticas(vacunasFiltradas),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vacunasFiltradas.length,
                  itemBuilder: (context, index) {
                    return _buildVacunaCard(vacunasFiltradas[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 📊 PANEL DE ESTADÍSTICAS
  Widget _buildEstadisticas(List<VacunaModel> vacunas) {
    final tiposUnicos = vacunas.map((v) => v.vacuna).toSet().length;
    final dosisTotal = vacunas.fold<int>(0, (sum, v) => sum + v.dosis);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEstadisticaItem(
            icon: Icons.vaccines,
            label: 'Vacunas',
            value: '${vacunas.length}',
            color: Colors.green,
          ),
          _buildEstadisticaItem(
            icon: Icons.category,
            label: 'Tipos',
            value: '$tiposUnicos',
            color: Colors.blue,
          ),
          _buildEstadisticaItem(
            icon: Icons.numbers,
            label: 'Dosis Total',
            value: '$dosisTotal',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // 🎛️ FILTROS
  Widget _buildFiltros(List<VacunaModel> vacunas) {
    final tiposVacunas = ['Todas', ...vacunas.map((v) => v.tipoVacunaCorto).toSet()];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tiposVacunas.length,
        itemBuilder: (context, index) {
          final tipo = tiposVacunas[index];
          final isSelected = tipo == _filtroTipo;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tipo),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filtroTipo = tipo;
                });
              },
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green.shade700,
            ),
          );
        },
      ),
    );
  }

  // 💳 TARJETA DE VACUNA
  Widget _buildVacunaCard(VacunaModel vacuna) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Vacuna y Dosis
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getVacunaColor(vacuna.vacuna).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.vaccines,
                    color: _getVacunaColor(vacuna.vacuna),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vacuna.vacuna,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dosis ${vacuna.dosis}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDosisChip(vacuna.dosis),
              ],
            ),
            
            const Divider(height: 24),
            
            // Información de la aplicación
            _buildInfoRow(Icons.calendar_today, 'Fecha', vacuna.fechaFormateada),
            _buildInfoRow(Icons.medical_services, 'Campaña', vacuna.campana),
            _buildInfoRow(Icons.qr_code, 'Lote', vacuna.lote),
            
            if (vacuna.aplicadoPor.isNotEmpty)
              _buildInfoRow(Icons.person, 'Aplicado por', vacuna.aplicadoPor),
            
            if (vacuna.observaciones != null && vacuna.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vacuna.observaciones!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosisChip(int dosis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${dosis}ª Dosis',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🎨 COLORES POR TIPO DE VACUNA
  Color _getVacunaColor(String vacuna) {
    if (vacuna.contains('COVID')) return Colors.red;
    if (vacuna.contains('Influenza')) return Colors.blue;
    if (vacuna.contains('Hepatitis')) return Colors.orange;
    if (vacuna.contains('Tétanos')) return Colors.purple;
    return Colors.green;
  }

  // 📭 ESTADO VACÍO
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vaccines_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin Registro de Vacunación',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay vacunas aplicadas registradas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<SessionProvider>(context, listen: false).loadVacunas();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
