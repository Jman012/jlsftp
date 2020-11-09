import Foundation

extension Result {
	var error: Failure? {
		switch self {
		case let .failure(err):
			return err
		case .success:
			return nil
		}
	}
}
