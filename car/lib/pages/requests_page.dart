import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/widgets/bottom_nav.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final ts = TranslationService();
  String? selectedFilter;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .schema('cartel')
          .from('requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const cardColor = Color(0xFF141414);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        final filters = [
          ts.translate('toutes'),
          ts.translate('initialisee'),
          ts.translate('en_cours'),
          ts.translate('terminee')
        ];
        
        selectedFilter ??= filters[0];

        final activeCount = _requests.where((r) => r['status'] != 'terminée').length;

        return Scaffold(
          backgroundColor: backgroundColor,
          extendBody: true,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(primaryColor, borderColor, ts, activeCount),
                _buildFilterBar(primaryColor, borderColor, mutedForeground, filters),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: primaryColor))
                      : _requests.isEmpty
                          ? Center(
                              child: Text(
                                ts.translate('no_requests_found'),
                                style: GoogleFonts.dmSans(color: mutedForeground),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                              itemCount: _filteredRequests().length,
                              separatorBuilder: (context, index) => const SizedBox(height: 24),
                              itemBuilder: (context, index) {
                                final request = _filteredRequests()[index];
                                final status = request['status'] ?? 'initialisée';
                                final isFinished = status == 'terminee' || status == 'terminée';
                                final isPulse = status == 'en cours' || status == 'en_cours';
                                
                                String dateStr = '';
                                try {
                                  final createdAt = DateTime.parse(request['created_at']);
                                  dateStr = 'CarTel Request • ${_formatDate(createdAt)}';
                                } catch (_) {
                                  dateStr = ts.translate('demande_cartel_aujourdhui');
                                }

                                return _buildRequestCard(
                                  title: '${request['make']} ${request['model']}',
                                  subtitle: dateStr,
                                  status: ts.translate(status.toString().toLowerCase().replaceAll(' ', '_')),
                                  id: '#${request['id'].toString().substring(0, 4).toUpperCase()}',
                                  budget: ts.formatPrice((request['budget_max'] ?? 0).toDouble()),
                                  agent: request['agent_id'] != null ? 'Agent Assigned' : ts.translate('attente_assignation_agent'),
                                  paymentStatus: request['payment_status'],
                                  step: status == 'initialisée' ? ts.translate('attente_assignation_agent') : ts.translate('identification_vehicules'),
                                  icon: isFinished ? Icons.verified_user_rounded : (isPulse ? Icons.directions_car_rounded : Icons.receipt_long_rounded),
                                  primaryColor: primaryColor,
                                  borderColor: borderColor,
                                  mutedForeground: mutedForeground,
                                  isPulse: isPulse,
                                  isFinished: isFinished,
                                  onTap: () {
                                    if ((status == 'initialisee' || status == 'initialisée') && (request['payment_status'] == 'pending' || request['payment_status'] == null)) {
                                      Navigator.pushNamed(context, '/create-request', arguments: request);
                                    } else {
                                      Navigator.pushNamed(context, '/request-details', arguments: request);
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) Navigator.pushReplacementNamed(context, '/home');
              if (index == 2) Navigator.pushReplacementNamed(context, '/notifications');
              if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(top: 32),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-request');
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
              elevation: 8,
              child: const Icon(Icons.add_rounded, size: 32),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filteredRequests() {
    if (selectedFilter == null || selectedFilter == ts.translate('toutes')) {
      return _requests;
    }
    return _requests.where((request) {
      final status = request['status']?.toString().toLowerCase();
      final translatedFilter = selectedFilter!.toLowerCase();
      
      if (translatedFilter == ts.translate('initialisee').toLowerCase()) {
        return status == 'initialisee' || status == 'initialisée';
      }
      if (translatedFilter == ts.translate('en_cours').toLowerCase()) {
        return status == 'en cours' || status == 'en_cours';
      }
      if (translatedFilter == ts.translate('terminee').toLowerCase()) {
        return status == 'terminee' || status == 'terminée';
      }
      return false;
    }).toList();
  }

  Widget _buildHeader(Color primaryColor, Color borderColor, TranslationService ts, int activeCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ts.translate('mes_demandes'),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$activeCount ${ts.translate('actives').toUpperCase()}',
                      style: GoogleFonts.dmSans(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(Color primaryColor, Color borderColor, Color mutedForeground, List<String> filters) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          bool isSelected = selectedFilter == filters[index];
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filters[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : const Color(0xFF1F1F1F).withOpacity(0.5),
                borderRadius: BorderRadius.circular(100),
                border: isSelected ? null : Border.all(color: borderColor.withOpacity(0.6)),
              ),
              child: Text(
                filters[index],
                style: GoogleFonts.dmSans(
                  color: isSelected ? Colors.black : mutedForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard({
    required String title,
    required String subtitle,
    required String status,
    required String id,
    String? budget,
    String? agent,
    String? paymentStatus,
    String? result,
    String? step,
    required IconData icon,
    bool isPulse = false,
    bool isFinished = false,
    required Color primaryColor,
    required Color borderColor,
    required Color mutedForeground,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414).withOpacity(0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: borderColor.withOpacity(0.6)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isFinished ? Colors.green.withOpacity(0.1) : (isPulse ? primaryColor.withOpacity(0.1) : const Color(0xFF1F1F1F)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isFinished ? Colors.green.withOpacity(0.2) : (isPulse ? primaryColor.withOpacity(0.2) : borderColor.withOpacity(0.5))),
                            ),
                            child: Icon(
                              icon,
                              color: isFinished ? Colors.green : (isPulse ? primaryColor : mutedForeground),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  color: mutedForeground,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFinished ? Colors.green.withOpacity(0.1) : (isPulse ? primaryColor.withOpacity(0.1) : const Color(0xFF1F1F1F).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isFinished ? Colors.green.withOpacity(0.2) : (isPulse ? primaryColor.withOpacity(0.2) : borderColor.withOpacity(0.6))),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.dmSans(
                                color: isFinished ? Colors.greenAccent : (isPulse ? primaryColor : mutedForeground),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            id,
                            style: GoogleFonts.dmSans(
                              color: mutedForeground,
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: borderColor.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFinished ? ts.translate('statut').toUpperCase() : ts.translate('budget_max').toUpperCase(),
                              style: GoogleFonts.dmSans(
                                color: mutedForeground,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              budget ?? '',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isFinished ? ts.translate('resultat').toUpperCase() : (paymentStatus != null ? ts.translate('paiement').toUpperCase() : ts.translate('agent').toUpperCase()),
                              style: GoogleFonts.dmSans(
                                color: mutedForeground,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  result ?? (paymentStatus ?? (agent ?? '')),
                                  style: GoogleFonts.montserrat(
                                    color: (paymentStatus != null || isFinished) ? (isFinished ? Colors.white : primaryColor) : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (agent != null) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 12),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isFinished)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor.withOpacity(0.2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ts.translate('consulter_rapport'),
                      style: GoogleFonts.dmSans(
                        color: mutedForeground,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios_rounded, color: mutedForeground, size: 14),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isPulse ? primaryColor : mutedForeground.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          step ?? '',
                          style: GoogleFonts.dmSans(
                            color: mutedForeground,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          ts.translate('details'),
                          style: GoogleFonts.dmSans(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios_rounded, color: primaryColor, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
