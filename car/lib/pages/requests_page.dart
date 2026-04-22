import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/widgets/bottom_nav.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/models/request_status.dart';

class RequestsPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const RequestsPage({super.key, this.supabaseClient});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  late final SupabaseClient _supabase;
  final ts = TranslationService();
  String? selectedFilter;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .schema('cartel')
          .from('requests')
          .select('*, agents(name, avatar_url)')
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

  Future<void> _deleteRequest(dynamic requestId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      debugPrint('Tentative de suppression de la demande ID: $requestId (type: ${requestId.runtimeType}) pour l\'utilisateur: ${user.id}');
      
      // Tentative 1: ID tel quel
      var response = await _supabase
          .schema('cartel')
          .from('requests')
          .delete()
          .eq('id', requestId)
          .eq('user_id', user.id)
          .select();
      
      // Tentative 2: ID en entier si échec et convertible
      if (response.isEmpty) {
        final intId = int.tryParse(requestId.toString());
        if (intId != null && intId.toString() != requestId.toString()) {
          debugPrint('Nouvelle tentative avec ID entier: $intId');
          response = await _supabase
              .schema('cartel')
              .from('requests')
              .delete()
              .eq('id', intId)
              .eq('user_id', user.id)
              .select();
        }
      }

      // Tentative 3: ID en chaîne si échec
      if (response.isEmpty) {
        final stringId = requestId.toString();
        if (stringId != requestId.toString()) { // avoid redundant check
           // already tried in Attempt 1 if it was string
        } else {
          debugPrint('Nouvelle tentative avec ID stringifié: $stringId');
          response = await _supabase
              .schema('cartel')
              .from('requests')
              .delete()
              .eq('id', stringId)
              .eq('user_id', user.id)
              .select();
        }
      }

      if (response.isEmpty) {
        debugPrint('AUCUNE LIGNE SUPPRIMÉE. Vérifiez l\'ID $requestId et le user_id ${user.id} dans la table cartel.requests');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${ts.translate('request_delete_error')} #$requestId'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          _fetchRequests(); 
        }
        return;
      }

      debugPrint('Suppression réussie: $response');
      if (mounted) {
        setState(() {
          _requests.removeWhere((r) => r['id'].toString() == requestId.toString());
        });

      }
    } catch (e) {
      debugPrint('Exception lors de la suppression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ts.translate('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _fetchRequests();
      }
    }
  }

  String _formatDate(DateTime date) {
    final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthsFr = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    final months = ts.currentLanguage == 'English' ? monthsEn : monthsFr;
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        final filters = [
          ts.translate('toutes'),
          ts.translate('initialisee'),
          ts.translate('en_cours'),
          ts.translate('trouve'),
          ts.translate('terminee')
        ];
        
        selectedFilter ??= filters[0];

        final activeCount = _requests.where((r) {
          final s = RequestStatusExtension.fromString(r['status']?.toString() ?? '');
          return s != RequestStatus.complete;
        }).length;

        return Scaffold(
          backgroundColor: backgroundColor,
          extendBody: true,
          body: SafeArea(
            bottom: false,
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
                                style: GoogleFonts.plusJakartaSans(color: mutedForeground),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                              itemCount: _filteredRequests().length,
                              separatorBuilder: (context, index) => const SizedBox(height: 24),
                                itemBuilder: (context, index) {
                                final request = _filteredRequests()[index];
                                final requestStatus = RequestStatusExtension.fromString(request['status']?.toString() ?? '');
                                final isFinished = requestStatus == RequestStatus.complete;
                                final isPulse = requestStatus == RequestStatus.inProgress;
                                final agentData = request['agents'];
                                final agentName = agentData?['name'] ?? ts.translate('unassigned');
                                final isUnassigned = request['agent_id'] == null;
                                final canEditOrDelete = requestStatus == RequestStatus.initiated && isUnassigned;
                                
                                IconData statusIcon;
                                switch (requestStatus) {
                                  case RequestStatus.initiated:
                                    statusIcon = Icons.note_add_rounded;
                                    break;
                                  case RequestStatus.inProgress:
                                    statusIcon = Icons.manage_search_rounded;
                                    break;
                                  case RequestStatus.found:
                                    statusIcon = Icons.auto_awesome_rounded;
                                    break;
                                  case RequestStatus.complete:
                                    statusIcon = Icons.check_circle_rounded;
                                    break;
                                }

                                String dateStr = '';
                                try {
                                  final createdAt = DateTime.parse(request['created_at']);
                                  dateStr = '${ts.translate('demande_cartel_aujourdhui').split('•').first} • ${_formatDate(createdAt)}';
                                } catch (_) {
                                  dateStr = ts.translate('demande_cartel_aujourdhui');
                                }

                                return Dismissible(
                                  key: Key(request['id'].toString()),
                                  direction: canEditOrDelete
                                      ? DismissDirection.endToStart 
                                      : DismissDirection.none,
                                  confirmDismiss: (direction) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: const Color(0xFF141414),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          side: const BorderSide(color: Color(0xFF2A2A2A)),
                                        ),
                                        title: Text(
                                          ts.translate('delete_request_title'),
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          ts.translate('delete_request_msg'),
                                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFFA3A3A3)),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text(
                                              ts.translate('cancel'),
                                              style: GoogleFonts.plusJakartaSans(
                                                color: const Color(0xFFA3A3A3),
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text(
                                              ts.translate('delete'),
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) {
                                    _deleteRequest(request['id']);
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 32),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
                                  ),
                                  child: _buildRequestCard(
                                    request: request,
                                    title: '${request['make']} ${request['model']}',
                                    subtitle: dateStr,
                                    status: ts.translate(requestStatus.translationKey),
                                    id: '#${request['id'].toString().substring(0, 4).toUpperCase()}',
                                    budget: ts.formatPrice((request['budget_max'] ?? 0).toDouble()),
                                    agent: agentName,
                                    paymentStatus: request['payment_status'] ?? 'Confirmé',
                                    step: requestStatus == RequestStatus.initiated ? ts.translate('attente_assignation_agent') : ts.translate('identification_vehicules'),
                                    icon: statusIcon,
                                    primaryColor: primaryColor,
                                    borderColor: borderColor,
                                    mutedForeground: mutedForeground,
                                    isPulse: isPulse,
                                    isFinished: isFinished,
                                    requestStatus: requestStatus,
                                    onTap: () {
                                      if (canEditOrDelete) {
                                        Navigator.pushNamed(context, '/create-request', arguments: request);
                                      } else {
                                        Navigator.pushNamed(context, '/request-details', arguments: request);
                                      }
                                    },
                                  ),
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
      final requestStatus = RequestStatusExtension.fromString(request['status']?.toString() ?? '');
      final translatedFilter = selectedFilter!.toLowerCase();
      
      if (translatedFilter == ts.translate('initialisee').toLowerCase()) {
        return requestStatus == RequestStatus.initiated;
      }
      if (translatedFilter == ts.translate('en_cours').toLowerCase()) {
        return requestStatus == RequestStatus.inProgress;
      }
      if (translatedFilter == ts.translate('trouve').toLowerCase()) {
        return requestStatus == RequestStatus.found;
      }
      if (translatedFilter == ts.translate('terminee').toLowerCase()) {
        return requestStatus == RequestStatus.complete;
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
                      '$activeCount ${ts.translate('actives')}',
                      style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(
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
    required Map<String, dynamic> request,
    required String title,
    required String subtitle,
    required String status,
    required String id,
    required String budget,
    required String agent,
    required String paymentStatus,
    required String step,
    required IconData icon,
    bool isPulse = false,
    bool isFinished = false,
    required Color primaryColor,
    required Color borderColor,
    required Color mutedForeground,
    VoidCallback? onTap,
    RequestStatus? requestStatus,
  }) {
    Color getStatusColor() {
      switch (requestStatus) {
        case RequestStatus.initiated:
          return const Color(0xFFA3A3A3);
        case RequestStatus.inProgress:
          return primaryColor;
        case RequestStatus.found:
          return const Color(0xFF60A5FA);
        case RequestStatus.complete:
          return const Color(0xFF10B981);
        default:
          return mutedForeground;
      }
    }

    final statusColorFinal = getStatusColor();
    final statusBgColor = statusColorFinal.withOpacity(0.1);
    final statusBorderColor = statusColorFinal.withOpacity(0.2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isFinished ? const Color(0xFF1F1F1F).withOpacity(0.8) : const Color(0xFF141414).withOpacity(0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: statusBorderColor),
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
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: statusBorderColor),
                              ),
                              child: Icon(
                                icon,
                                color: statusColorFinal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: mutedForeground,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusBorderColor),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: statusColorFinal,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          const SizedBox(height: 4),
                          Text(
                            id,
                            style: GoogleFonts.plusJakartaSans(
                              color: mutedForeground,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.symmetric(horizontal: BorderSide(color: borderColor.withOpacity(0.2))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ts.translate('budget_max'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: mutedForeground,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                budget,
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
                                isFinished ? ts.translate('statut') : (isPulse ? ts.translate('agent') : ts.translate('paiement')),
                                style: GoogleFonts.plusJakartaSans(
                                  color: mutedForeground,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isFinished)
                                Text(
                                  ts.translate('livre'),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else if (isPulse)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      agent,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, color: Colors.blue, size: 12),
                                  ],
                                )
                              else
                                Text(
                                  ts.translate('confirme'),
                                  style: GoogleFonts.montserrat(
                                    color: primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isFinished)
                    _buildPrimaryButton(
                      label: ts.translate('leave_review'),
                      icon: Icons.star_rounded,
                      onTap: () => Navigator.pushNamed(context, '/leave-review', arguments: request),
                    )
                  else
                    Row(
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
                              step,
                              style: GoogleFonts.plusJakartaSans(
                                color: mutedForeground,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: onTap,
                          child: Row(
                            children: [
                              Text(
                                ts.translate('details'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, color: primaryColor, size: 10),
                            ],
                          ),
                        ),
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

  Widget _buildPrimaryButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
