//
//  Errors.swift
//  ChanDit
//
//  Created by Bemacash on 11/12/19.
//  Copyright © 2019 Vinicius Valvassori. All rights reserved.
//

import UIKit

enum Errors: Error {
    case imageTemporaryDirectoryCreationError
}

extension Errors: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .imageTemporaryDirectoryCreationError:
            return NSLocalizedString("Diretório temporário não pode ser criado",
                                     comment: "Falha ao criar diretório temporário")
        }
    }
    public var failureReason: String? {
        switch self {
        case .imageTemporaryDirectoryCreationError: return "Não foi possível criar o diretório temporário"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .imageTemporaryDirectoryCreationError: return "Tente novamente mais tarde"
        }
    }
}
