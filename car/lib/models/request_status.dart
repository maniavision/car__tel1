enum RequestStatus {
  initiated,
  inProgress,
  found,
  complete,
}

extension RequestStatusExtension on RequestStatus {
  String get translationKey {
    switch (this) {
      case RequestStatus.initiated:
        return 'initialisee';
      case RequestStatus.inProgress:
        return 'en_cours';
      case RequestStatus.found:
        return 'trouve';
      case RequestStatus.complete:
        return 'terminee';
    }
  }

  String get dbValue {
    switch (this) {
      case RequestStatus.initiated:
        return 'Initiated';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.found:
        return 'Found';
      case RequestStatus.complete:
        return 'Complete';
    }
  }

  static RequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'initiated':
      case 'initialisée':
      case 'initialisee':
        return RequestStatus.initiated;
      case 'in progress':
      case 'in_progress':
      case 'en_cours':
      case 'en cours':
        return RequestStatus.inProgress;
      case 'found':
      case 'trouvé':
      case 'trouvée':
        return RequestStatus.found;
      case 'complete':
      case 'terminée':
      case 'terminee':
        return RequestStatus.complete;
      default:
        return RequestStatus.initiated;
    }
  }
}
